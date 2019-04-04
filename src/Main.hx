package;

import battle.IInteractiveModel;
import battle.Model;
import battle.Unit;
import battle.enums.Team;
import battle.struct.UnitCoords;
import haxe.Timer;
import haxe.crypto.Md5;
import mphx.connection.IConnection;
import mphx.server.impl.Server;
import mphx.server.room.Room;
import roaming.Unit.RoamUnitParameters;
import roaming.Player;
import sys.io.File;

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
	private static var loginManager:LoginManager;
	
	static function main() 
	{
		server = new Server("localhost", 5000);
		loginManager = new LoginManager();
		
		server.events.on("Login", function(data:LoginPair, sender:IConnection){
			loginManager.login(data, sender);
		});
		
		server.onConnectionClose = function(s:String, c:IConnection){
			loginManager.logout(c); 
			battleExecute(true, c, function(l:String){models[l].quit(l); models.remove(l); });
			var l:String = loginManager.getLogin(c);
			if (l != null)
				if (rooms[l] != null)
				{
					for (i in 0...openRooms.length)
						if (openRooms[i] == l)
						{
							openRooms.splice(i, 1);
							break;
						}
					for (i in 0...server.rooms.length)
						if (server.rooms[i] == rooms[l])
						{
							server.rooms.splice(i, 1);
							break;
						}
					rooms.remove(l);
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
			battleExecute(false, sender, function(l:String, fcs:Focus){models[l].useRequest(l, fcs.abilityNum, fcs.target); }, focus);
		});
		
		server.events.on("SkipTurn", function(data:Dynamic, sender:IConnection){
			battleExecute(false, sender, function(l:String){models[l].skipTurn(l); });
		});
		
		server.events.on("QuitBattle", function(data:Dynamic, sender:IConnection){
			battleExecute(false, sender, function(l:String){models[l].quit(l); });
		});
		
		server.start();
	}
	
	private static function battleExecute(silent:Bool, requester:IConnection, ?func:String->Void, ?hfunc:String->Focus->Void, ?hdata:Focus)
	{
		var l:String = loginManager.getLogin(requester);
		if (l != null)
		{
			if (models[l] != null)
				func != null? func(l) : hfunc(l, hdata);
			else if (!silent)
				requester.send("NotInBattle");
		}
		else if (!silent)
			requester.send("LoginNeeded");
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
		rooms[players[0]].broadcast("BattleEnded", winners);
		for (l in players) rooms.remove(l);
	}
	
	public static function warn(login:String, message:String)
	{
		var c:IConnection = loginManager.getConnection(login);
		if (c != null)
			c.send("BattleWarning", {message:message, state: models[login].getPersonal(login)});
	}
	
	private static function findMatch(sender:IConnection)
	{
		var peer:String = loginManager.getLogin(sender);
		if (Lambda.empty(openRooms))
		{
			var room:BattleRoom = new BattleRoom();
			sender.putInRoom(room); //Putting in room
			room.map(peer, sender); //Allowing to access from it by login
			rooms[peer] = room; //Creating a link
			server.rooms.push(room); //Adding the room to server
			openRooms.push(peer); //Hey, I'm lfg
			trace(openRooms);
		}
		else
		{
			var enemy:String = openRooms.splice(0, 1)[0];
			sender.putInRoom(rooms[enemy]);
			rooms[enemy].map(peer, sender);
			rooms[peer] = rooms[enemy];
			#if debug trace(1); #end
			var p1:Unit = loadUnit(enemy, Team.Left, 0);
			#if debug trace(1); #end
			var p2:Unit = loadUnit(peer, Team.Right, 0);
			#if debug trace(1); #end
			models[enemy] = new Model([p1], [p2], rooms[peer]);
			#if debug trace(1); #end
			models[peer] = models[enemy];
			var awaitingAnswer:Array<String> = [for (k in rooms[enemy].clientMap.keys()) k];
			trace(rooms[enemy].clientMap);
			server.events.on("InitialDataRecieved", function(data:Dynamic, sender:IConnection){
				var l:String = loginManager.getLogin(sender);
				if (l != null)
					for (i in 0...awaitingAnswer.length)
						if (awaitingAnswer[i] == l)
						{
							awaitingAnswer.splice(i, 1);
							if (Lambda.empty(awaitingAnswer))
								models[peer].start();
							break;
						}
			});
			rooms[peer].broadcast("BattleStarted", models[peer].getInitialState());
			for (l in rooms[peer].clientMap.keys())
				rooms[peer].clientMap[l].send("BattlePersonal", models[peer].getPersonal(l));
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