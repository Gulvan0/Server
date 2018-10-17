package;

import battle.IInteractiveModel;
import battle.Model;
import haxe.crypto.Md5;
import mphx.connection.IConnection;
import mphx.server.impl.Server;
import mphx.server.room.Room;
import sys.io.File;

typedef LoginPair = {
  var login:String;
  var password:String;
}
/**
 * ...
 * @author Gulvan
 */
class Main 
{
	private static var models:Map<String, IInteractiveModel> = new Map();
	private static var rooms:Map<String, Room> = new Map();
	private static var battles:Map<String, String> = new Map();
	private static var openRooms:Array<String> = [];
	
	private static var server:Server;
	private static var loggedPlayers:Map<String, String> = new Map();
	
	static function main() 
	{
		server = new Server("0.0.0.0", 5000);
		trace("Server started");
		
		server.events.on("Login", function(data:LoginPair, sender:IConnection){
			if (checkPassword(data))
				loggedPlayers[sender.getContext().peerToString()] = data.login;
		});
		
		server.events.on("Register", function(data:LoginPair, sender:IConnection){
			if (!loggedPlayers.exists(sender.getContext().peerToString()))
				register(data);
		});
		
		server.events.on("FindMatch", function(data:Dynamic, sender:IConnection){
			if (loggedPlayers.exists(sender.getContext().peerToString()))
				findMatch(sender);
		});
	}
	
	public static function findMatch(sender:IConnection)
	{
		var peer:String = loggedPlayers[sender.getContext().peerToString()];
		if (Lambda.empty(openRooms))
		{
			var room:Room = new Room();
			sender.putInRoom(room);
			rooms[peer] = room;
			server.rooms.push(room);
			battles[peer] = peer;
			openRooms.push(peer);
		}
		else
		{
			var battleID:String = openRooms.splice(0, 1)[0];
			battles[peer] = battleID;
			sender.putInRoom(rooms[battleID]);
			models[battleID] = new Model([], []);
		}
	}
	
	private static function register(pair:LoginPair)
	{
		if (pair.login.length >= 2)
			File.saveContent(loginPath(), File.getContent(loginPath()) + "\n<player login=\"" + pair.login + "\">" + Md5.encode(pair.password) + "</player>");
	}
	
	private static function checkPassword(pair:LoginPair):Bool
	{
		var xml:Xml = Xml.parse(File.getContent(loginPath()));
		
		for (p in xml.elementsNamed("player"))
		{
			if (p.get("login") == pair.login)
				return Md5.encode(pair.password) == p.firstChild().nodeValue;
		}
		
		return false;
	}
	
	private static function loginPath():String
	{
		var path:String = Sys.programPath();
		path = path.substring(0, path.lastIndexOf("\\"));
		path = path.substring(0, path.lastIndexOf("\\"));
		path += "\\playerdata\\players.xml";
		return path;
	}
	
}