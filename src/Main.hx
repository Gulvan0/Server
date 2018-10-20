package;

import battle.IInteractiveModel;
import battle.Model;
import battle.Unit;
import battle.enums.Team;
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

typedef Update = {
	var model:Model;
	var event:String;
}
/**
 * ...
 * @author Gulvan
 */
class Main 
{
	private static var models:Map<String, IInteractiveModel> = new Map(); // id -> Model
	private static var rooms:Map<String, BattleRoom> = new Map(); // id -> Room
	private static var battleidByLogin:Map<String, String> = new Map(); // login -> id
	private static var openRoomIDs:Array<String> = [];
	
	private static var server:Server;
	private static var loginManager:LoginManager;
	
	static function main() 
	{
		loginManager = new LoginManager();
		server = new Server("0.0.0.0", 5000);
		trace("Server started");
		
		server.events.on("Login", function(data:LoginPair, sender:IConnection){
			loginManager.login(data, sender);
		});
		
		server.events.on("Register", function(data:LoginPair, sender:IConnection){
			if (loginManager.register(data, sender))
				loginManager.login(data, sender);
		});
		
		server.events.on("GetPlayer", function(data:Dynamic, sender:IConnection){
			var l:String = loginManager.getLogin(sender);
			if (l != null)
				sender.send("SendPlayer", File.getContent(playersDir() + l + ".xml"));
			else
				sender.send("LoginNeeded");
		});
		
		server.events.on("FindMatch", function(data:Dynamic, sender:IConnection){
			if (loginManager.getLogin(sender) != null)
				findMatch(sender);
			else
				sender.send("LoginNeeded");
		});
		
		server.events.on("GetBattlePersonal", function(data:Dynamic, sender:IConnection){
			var l:String = loginManager.getLogin(sender);
			if (l != null)
			{
				var b:String = battleidByLogin[l];
				if (b != null)
					sender.send("BattlePersonalInfo", models[b].getPersonal(l));
				else
					sender.send("NotInBattle");
			}
			else
				sender.send("LoginNeeded");
		});
		
		while (true) {}
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
			// Additional processing when draw == true
		//Then save all the changes
		
		var bid:String = battleidByLogin[Lambda.empty(winners)? losers[0] : winners[0]];
		models.remove(bid);
		rooms[bid].broadcast("BattleEnded", winners);
		rooms.remove(bid);
		
		for (l in winners.concat(losers))
			battleidByLogin.remove(l);
	}
	
	public static function update(someoneFromBattle:String, event:String)
	{
		var b:String = battleidByLogin[someoneFromBattle];
		if (b != null)
			rooms[b].broadcast("BattleUpdated", {model: models[b].getState(), event: event});
	}
	
	public static function warn(login:String, warning:String)
	{
		var c:IConnection = loginManager.getConnection(login);
		if (c != null)
			c.send("Warning", warning);
	}
	
	private static function findMatch(sender:IConnection)
	{
		var peer:String = loginManager.getLogin(sender);
		if (Lambda.empty(openRoomIDs))
		{
			var room:BattleRoom = new BattleRoom();
			sender.putInRoom(room);
			room.map(peer, sender);
			rooms[peer] = room;
			server.rooms.push(room);
			battleidByLogin[peer] = peer; // (Refers to this assumption)
			openRoomIDs.push(peer);
		}
		else
		{
			var battleID:String = openRoomIDs.splice(0, 1)[0];
			battleidByLogin[peer] = battleID;
			sender.putInRoom(rooms[battleID]);
			rooms[battleID].map(peer, sender);
			models[battleID] = new Model([loadUnit(battleID, Team.Left, 0)], [loadUnit(peer, Team.Right, 0)]); //battleID as login - temporary
			rooms[battleID].broadcast("BattleStarted", models[battleID].getState());
		}
	}
	
	private static function loadUnit(login:String, team:Team, pos:Int):Unit
	{
		return new Unit(ID.Player(login), team, pos, loadPlayer(login).toParams());
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
		}
		
		return new Player(login, element, params, name);
	}
	
	public static function playersDir():String
	{
		var path:String = Sys.programPath();
		path = path.substring(0, path.lastIndexOf("\\"));
		path = path.substring(0, path.lastIndexOf("\\"));
		path += "\\playerdata\\";
		return path;
	}
	
}