package;

import roaming.enums.Attribute;
import GameRules.BattleOutcome;
import battle.IInteractiveModel;
import battle.Model;
import battle.Unit;
import battle.enums.Team;
import battle.struct.UnitCoords;
import haxe.Timer;
import haxe.crypto.Md5;
import json2object.JsonWriter;
import mphx.connection.IConnection;
import mphx.server.impl.Server;
import mphx.server.room.Room;
import roaming.Player;
import sys.io.File;
using Utils;

typedef LoginPair = {
  var login:String;
  var password:String;
}

typedef Focus = {
  var abilityNum:Int;
  var target:UnitCoords;
}

/**
 * ...
 * @author Gulvan
 */
class Main 
{
	public static var version:String = "alpha2.4";

	private static var models:Map<String, IInteractiveModel> = new Map(); // login -> Model
	private static var rooms:Map<String, BattleRoom> = new Map(); // login -> Room
	private static var openRooms:Array<String> = [];
	
	private static var server:Server;
	public static var loginManager:LoginManager;
	
	static function main()
	{
		init();
	}
	
	private static function init() 
	{
		server = new Server("localhost", 5000);
		loginManager = new LoginManager();
		
		server.events.on("Login", function(data:LoginPair, sender:IConnection){
			loginManager.login(data, sender);
		});
		
		server.onConnectionClose = function(s:String, c:IConnection){
			var l:String = loginManager.getLogin(c);
			if (l != null)
			{
				if (models[l] != null)
				{
					rooms[l].clients.remove(l);
					models[l].quit(l);
					models.remove(l);
				}
				
				rooms.remove(l);
				openRooms.remove(l);
				loginManager.logout(c);
			}
		};
		
		server.events.on("Register", function(data:LoginPair, sender:IConnection){
			if (loginManager.register(data, sender))
				loginManager.login(data, sender);
		});
		
		server.events.on("FindMatch", function(data:Dynamic, sender:IConnection){
			if (loginManager.getLogin(sender) != null)
				findMatch(sender);
			else
				sender.send("LoginNeeded");
		});
		
		server.events.on("UseRequest", function(focus:Focus, sender:IConnection){
			var l:Null<String> = getModel(false, sender);
			if (l != null)
				models[l].useRequest(l, focus.abilityNum, focus.target);
		});
		
		server.events.on("SkipTurn", function(data:Dynamic, sender:IConnection){
			var l:Null<String> = getModel(false, sender);
			if (l != null)
				models[l].skipTurn(l);
		});
		
		server.events.on("QuitBattle", function(data:Dynamic, sender:IConnection){
			var l:Null<String> = getModel(false, sender);
			if (l != null)
				models[l].quit(l);
		});

		server.events.on("GetVersion", function(data:Dynamic, sender:IConnection){
			sender.send("Version", version);
		});
		
		server.start();
	}
	
	private static function getModel(silent:Bool, requester:IConnection):Null<String>
	{
		var l:String = loginManager.getLogin(requester);
		if (l != null)
		{
			if (models[l] != null)
				return l;
			else if (!silent)
				requester.send("NotInBattle");
		}
		else if (!silent)
			requester.send("LoginNeeded");
		return null;
	}
	
	public static function terminate(winners:Array<String>, losers:Array<String>, ?draw:Bool = false)
	{
		var w:Array<Player> = [for (login in winners) new Player(login)];
		var l:Array<Player> = [for (login in losers) new Player(login)];
		var pvp:Bool = !Lambda.empty(losers) && !Lambda.empty(winners);
		var deltaRating:Int = 0;
		for (player in w) deltaRating += player.rating;
		for (player in l) deltaRating -= player.rating;
		deltaRating = Math.round(Math.abs(deltaRating));

		for (player in w)
			if (pvp)
			{
				player.gainXP(GameRules.xpRewardPVP(draw? BattleOutcome.Draw : BattleOutcome.Win));
				player.rating += GameRules.ratingRewardPVP(draw? BattleOutcome.Draw : BattleOutcome.Win, deltaRating);
			}
			else 
				player.gainXP(GameRules.xpRewardPVE(draw? BattleOutcome.Draw : BattleOutcome.Win, player.isAtBossStage()));
		for (player in l)
			if (pvp)
			{
				player.gainXP(GameRules.xpRewardPVP(draw? BattleOutcome.Draw : BattleOutcome.Loss));
				player.rating += GameRules.ratingRewardPVP(draw? BattleOutcome.Draw : BattleOutcome.Loss, deltaRating);
			}
			else 
				player.gainXP(GameRules.xpRewardPVE(draw? BattleOutcome.Draw : BattleOutcome.Loss, player.isAtBossStage()));

		var players:Array<String> = winners.concat(losers);
		for (l in players) models.remove(l);
		var writer = new JsonWriter<Array<String>>();
		rooms[players[0]].broadcast("BattleEnded", draw? "DRAW" : writer.write(winners));
		for (l in players) rooms.remove(l);
	}
	
	public static function warn(login:String, message:String)
	{
		var c:IConnection = loginManager.getConnection(login);
		if (c != null)
			c.send("BattleWarning", {message:message, state: models[login].getPersonal(login)});
		trace(message);
	}
	
	private static function findMatch(sender:IConnection)
	{
		var peer:String = loginManager.getLogin(sender);
		if (Lambda.empty(openRooms))
		{
			var room:BattleRoom = new BattleRoom();
			trace(room);
			room.add(peer); //Allowing to access from it by login
			trace(room);
			rooms[peer] = room; //Creating a link
			trace(rooms);
			openRooms.push(peer); //Hey, I'm lfg
			trace(openRooms);
		}
		else
		{
			var enemy:String = openRooms.splice(0, 1)[0];
			rooms[enemy].add(peer);
			rooms[peer] = rooms[enemy];
			#if debug trace(1); #end
			var p1:Unit = loadUnit(enemy, Team.Left, 0);
			#if debug trace(1); #end
			var p2:Unit = loadUnit(peer, Team.Right, 0);
			models[enemy] = new Model([p1], [p2], rooms[peer]);
			models[peer] = models[enemy];
			#if debug trace(1, rooms[enemy]); #end
			
			var awaitingAnswer:Array<String> = rooms[enemy].clients.copy();
			#if debug trace("Waiting ", awaitingAnswer); #end
			server.events.on("InitialDataRecieved", function(data:Dynamic, sender:IConnection){answerHandler(sender, awaitingAnswer, models[peer]); });
			
			for (l in rooms[peer].clients)
			{
				var c:IConnection = loginManager.getConnection(l);
				var d:String = models[peer].getPersonal(l);
				c.send("BattlePersonal", d);
			}
			rooms[peer].broadcast("BattleStarted", models[peer].getInitialState());
		}
	}
	
	private static function answerHandler(sender:IConnection, array:Array<String>, model:IInteractiveModel)
	{
		var l:String = loginManager.getLogin(sender);
		if (l != null)
		{
			array.remove(l);
			trace(array);
			if (Lambda.empty(array))
			{
				server.events.remove("InitialDataRecieved");
				model.start();
			}
		}
	}
	
	private function createEnemyArray(zone:Zone, stage:Int):Array<Unit>
	{
		var enemyIDs:Array<ID> = XMLUtils.parseStage(zone, stage);
		var enemies:Array<Unit> = [];
		for (i in 0...enemyIDs.length)
			enemies.push(new Unit(enemyIDs[i], Team.Right, i));
			
		return enemies;
	}
	
	private static function loadUnit(login:String, team:Team, pos:Int):Unit
	{
		var i:ID = ID.Player(login);
		var par:ParameterList = new Player(login).toParams();
		return new Unit(i, team, pos, par);
	}
	
	public static function playersDir():String
	{
		var path:String = Sys.programPath();
		path = path.substring(0, path.lastIndexOf("\\"));
		path += "\\playerdata\\";
		return path;
	}

	public static function gamedataDir():String
	{
		var path:String = Sys.programPath();
		path = path.substring(0, path.lastIndexOf("\\"));
		path += "\\data\\";
		return path;
	}

	public static function playerData(login:String):Xml
	{
		return  Xml.parse(File.getContent(playersDir() + login + ".xml"));
	}
	
}