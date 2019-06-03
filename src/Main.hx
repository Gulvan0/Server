package;

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
import roaming.Unit.RoamUnitParameters;
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
		server = new Server("ec2-18-224-7-170.us-east-2.compute.amazonaws.com", 5000);
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
		//As follows:
		//if (winner == Team.Left) //If PvE
			//if (Main.progress.isBossStage())
			//{
				//Main.player.gainXP(50);
				//Main.progress.proceed();
			//}
			//else
			//{
				//Main.progress.proceed();
				//if (Main.progress.isBossStage())
					//Main.player.gainXP(75);
				//else
					//Main.player.gainXP(40);
			//}
		////+ If PvP
			// +xp +xp
			// Additional processing when draw == true AND MAKE SURE PLAYERS ARRAY WONT BE EMPTY
		//Then save all the changes
		
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
		#if debug trace(2); #end
		var i:ID = ID.Player(login);
		#if debug trace(2); #end
		var p:Player = loadPlayer(login);
		#if debug trace(2); #end
		var par:ParameterList = p.toParams();
		#if debug trace(2); #end
		return new Unit(i, team, pos, par);
	}
	
	private static function loadPlayer(login:String):Player
	{
		var xml:Xml = Xml.parse(File.getContent(playersDir() + login + ".xml"));
		var name:String;
		var element:Element;
		var params:RoamUnitParameters = new RoamUnitParameters();
		
		for (p in xml.elementsNamed("player"))
		{
			for (n in p.elementsNamed("name"))
				name = n.firstChild().nodeValue;
			for (n in p.elementsNamed("element"))
				element = Type.createEnum(Element, n.firstChild().nodeValue);
			for (n in p.elementsNamed("xp"))
				params.xp = Std.parseInt(n.firstChild().nodeValue);
			for (n in p.elementsNamed("level"))
				params.level = Std.parseInt(n.firstChild().nodeValue);
			for (n in p.elementsNamed("abp"))
				params.abilityPoints = Std.parseInt(n.firstChild().nodeValue);
			for (n in p.elementsNamed("attp"))
				params.attributePoints = Std.parseInt(n.firstChild().nodeValue);
			for (n in p.elementsNamed("st"))
				params.strength = Std.parseInt(n.firstChild().nodeValue);
			for (n in p.elementsNamed("fl"))
				params.flow = Std.parseInt(n.firstChild().nodeValue);
			for (n in p.elementsNamed("in"))
				params.intellect = Std.parseInt(n.firstChild().nodeValue);
			params.wheel = [];
			for (n in p.elementsNamed("wheel"))
				for (n in n.elementsNamed("ability"))
					params.wheel.push(Type.createEnum(ID, n.firstChild().nodeValue));
		}
		return new Player(login, element, params, name);
	}
	
	public static function playersDir():String
	{
		var path:String = Sys.programPath();
		path = path.substring(0, path.lastIndexOf("\\"));
		path += "\\playerdata\\";
		return path;
	}
	
}