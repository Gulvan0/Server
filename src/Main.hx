package;

import managers.CommandManager;
import sys.thread.Thread;
import managers.PlayerdataManager;
import managers.AbilityManager;
import managers.BuffManager;
import managers.LoginManager;
import MathUtils.IntPoint;
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
import sys.io.File;
import managers.ConnectionManager;
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
	public static var version:String = "alpha3.6";
	public static var playersDir:String;
	public static var gamedataDir:String;
	
	static function main()
	{
		playersDir = getPlayersDir();
		gamedataDir = getGamedataDir();
		Sys.println("Reading abilities");
		AbilityManager.init();
		Sys.println("Reading buffs");
		BuffManager.init();
		Sys.println("Initializing connection");
		Thread.create(()->{CommandManager.processLine(Sys.stdin().readLine());});
		ConnectionManager.init();
	}
	
	private static function getPlayersDir():String
	{
		var path:String = Sys.programPath();
		path = path.substring(0, path.lastIndexOf("\\"));
		path += "\\playerdata\\";
		return path;
	}

	private static function getGamedataDir():String
	{
		var path:String = Sys.programPath();
		path = path.substring(0, path.lastIndexOf("\\"));
		path += "\\data\\";
		return path;
	}
	
}