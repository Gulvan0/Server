package;

import MathUtils.IntPoint;
import battle.data.BH;
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
	public static var version:String = "alpha2.5";

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
		#if local
		server = new Server("localhost", 5000);
		#else
		server = new Server("ec2-18-222-25-127.us-east-2.compute.amazonaws.com", 5000);
		#end
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

		server.events.on("LearnAbility", function(d:String, sender:IConnection){
			var l:Null<String> = loginManager.getLogin(sender);
			var data:Array<Null<Int>> = d.split("|").map(Std.parseInt);
			if (l != null)
				new Player(l).learnAbility(data[0], data[1]);
			else
				sender.send("LoginNeeded");
		});

		server.events.on("PutAbility", function(d:String, sender:IConnection){
			var l:Null<String> = loginManager.getLogin(sender);
			var data:Array<String> = d.split("|");
			if (l != null)
				new Player(l).addToWheel(ID.createByName(data[0]), Std.parseInt(data[1]));
			else
				sender.send("LoginNeeded");
		});

		server.events.on("RemoveAbility", function(d:String, sender:IConnection){
			var l:Null<String> = loginManager.getLogin(sender);
			if (l != null)
				new Player(l).removeFromWheel(Std.parseInt(d));
			else
				sender.send("LoginNeeded");
		});

		server.events.on("IncrementAttribute", function(d:String, sender:IConnection){
			var l:Null<String> = loginManager.getLogin(sender);
			if (l != null)
				new Player(l).incrementAtt(Attribute.createByName(d));
			else
				sender.send("LoginNeeded");
		});

		server.events.on("ReSpec", function(d:Dynamic, sender:IConnection){
			var l:Null<String> = loginManager.getLogin(sender);
			if (l != null)
			{
				new Player(l).reSpec();
				loginManager.sendPlPrData(sender);
			}
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

		server.events.on("BHTick", function(data:Dynamic, sender:IConnection){
			var l:Null<String> = getModel(false, sender);
			if (l != null)
				rooms[l].share(l, "BHTick", data);
		});

		server.events.on("BHVanish", function(data:Dynamic, sender:IConnection){
			var l:Null<String> = getModel(false, sender);
			if (l != null)
				rooms[l].share(l, "BHVanish", data);
		});

		server.events.on("BHBoom", function(data:Dynamic, sender:IConnection){
			var l:Null<String> = getModel(false, sender);
			if (l != null)
				models[l].boom(l);
		});

		server.events.on("BHFinished", function(data:Dynamic, sender:IConnection){
			var l:Null<String> = getModel(false, sender);
			if (l != null)
			{
				var responsesAwaited:Int = rooms[l].clients.length - 1;
				server.events.on("DemoClosed", function (d:Dynamic, s:IConnection){
					responsesAwaited--;
					if (responsesAwaited == 0)
					{
						server.events.remove("DemoClosed");
						sender.send("BHCloseGame");
						models[l].bhOver(l);
					}
				});
				rooms[l].share(l, "BHCloseDemo");
			}
		});

		server.events.on("SetPatternByPos", function(d:{abI:Int, abJ:Int, num:Int, pattern:String}, sender:IConnection){
			var l:Null<String> = loginManager.getLogin(sender);
			if (l != null)
			{
				new Player(l).setPattern(d.abI, d.abJ, d.num, d.pattern);
				sender.send("PatternSet");
			}
			else
				sender.send("LoginNeeded");
		});

		server.events.on("SetPatternByID", function(data:{id:String, num:Int, pattern:String}, sender:IConnection){
			if (loginManager.getLogin(sender) != null)
			{
				var pl:Player = new Player(loginManager.getLogin(sender));
				var pos:IntPoint = pl.findAbility(ID.createByName(data.id));
				pl.setPattern(pos.i, pos.j, data.num, data.pattern);
				sender.send("PatternSet");
			}
			else
				sender.send("LoginNeeded");
		});

		server.events.on("SetPatternsByID", function(data:{id:String, patterns:String}, sender:IConnection){
			if (loginManager.getLogin(sender) != null)
			{
				var pl:Player = new Player(loginManager.getLogin(sender));
				var pos:IntPoint = pl.findAbility(ID.createByName(data.id));
				pl.setPatterns(pos.i, pos.j, data.patterns);
				sender.send("PatternSet");
			}
			else
				sender.send("LoginNeeded");
		});

		server.events.on("GetVersion", function(data:Dynamic, sender:IConnection){
			sender.send("Version", version);
		});

		//Should be unused because client should know the parameters
		server.events.on("GetBHParams", function(id:String, sender:IConnection){
			var writer:JsonWriter<Array<BHParameterDetails>> = new JsonWriter<Array<BHParameterDetails>>();
			sender.send("BHParams", writer.write(BH.getParameterDetails(ID.createByName(id))));
		});

		server.events.on("GetBHPatternByPos", function(data:{i:Int, j:Int, num:Int}, sender:IConnection){
			if (loginManager.getLogin(sender) != null)
				sender.send("BHPattern", new Player(loginManager.getLogin(sender)).getPattern(data.i, data.j, data.num));
			else
				sender.send("LoginNeeded");
		});

		server.events.on("GetBHPatternByID", function(data:{id:String, num:Int}, sender:IConnection){
			if (loginManager.getLogin(sender) != null)
			{
				var pl:Player = new Player(loginManager.getLogin(sender));
				var pos:IntPoint = pl.findAbility(ID.createByName(data.id));
				sender.send("BHPattern", pl.getPattern(pos.i, pos.j, data.num));
			}
			else
				sender.send("LoginNeeded");
		});

		server.events.on("GetPlPrData", function(data:Dynamic, sender:IConnection){
			if (loginManager.getLogin(sender) != null)
				loginManager.sendPlPrData(sender);
			else
				sender.send("LoginNeeded");
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

		var xpRewards:Map<String, Int> = [];
		var ratingRewards:Map<String, Null<Int>> = [];
		for (player in w)
			if (pvp)
			{
				xpRewards[player.login] = GameRules.xpRewardPVP(draw? BattleOutcome.Draw : BattleOutcome.Win);
				ratingRewards[player.login] = GameRules.ratingRewardPVP(draw? BattleOutcome.Draw : BattleOutcome.Win, deltaRating);
				player.gainXP(xpRewards[player.login]);
				player.rating += ratingRewards[player.login];
			}
			else
			{
				xpRewards[player.login] = GameRules.xpRewardPVE(draw? BattleOutcome.Draw : BattleOutcome.Win, player.isAtBossStage());
				ratingRewards[player.login] = null;
				player.gainXP(xpRewards[player.login]);
			}
		for (player in l)
			if (pvp)
			{
				xpRewards[player.login] = GameRules.xpRewardPVP(draw? BattleOutcome.Draw : BattleOutcome.Loss);
				ratingRewards[player.login] = GameRules.ratingRewardPVP(draw? BattleOutcome.Draw : BattleOutcome.Loss, deltaRating);
				player.gainXP(xpRewards[player.login]);
				player.rating += ratingRewards[player.login];
			}
			else
			{
				xpRewards[player.login] = GameRules.xpRewardPVE(draw? BattleOutcome.Draw : BattleOutcome.Loss, player.isAtBossStage());
				ratingRewards[player.login] = null;
				player.gainXP(xpRewards[player.login]);
			}

		for (l in winners.concat(losers)) 
		{
			var resultString:String = draw? "DRAW" : Lambda.has(winners, l)? "WIN" : "LOSS";
			rooms.remove(l);
			models.remove(l);
			loginManager.getConnection(l).send("BattleEnded", {outcome: resultString, xp: xpRewards[l], rating: ratingRewards[l]});
		}
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
			var p1:Unit = loadUnit(enemy, Team.Left, 0);
			var p2:Unit = loadUnit(peer, Team.Right, 0);
			models[enemy] = new Model([p1], [p2], rooms[peer]);
			models[peer] = models[enemy];
			
			var awaitingAnswer:Array<String> = rooms[enemy].clients.copy();
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