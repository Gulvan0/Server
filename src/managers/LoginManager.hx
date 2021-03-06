package managers;
import managers.PlayerdataManager.ClassRecord;
import managers.PlayerdataManager.Playerdata;
import haxe.Json;
import sys.io.FileOutput;
import sys.FileSystem;
import haxe.crypto.Md5;
import mphx.connection.IConnection;
import Main.LoginPair;
import sys.io.File;
using StringTools;

typedef RoamData = {player:Playerdata, record:Array<ClassRecord>}

/**
 * @author gulvan
 */
class LoginManager 
{
	public static var instance:LoginManager;
	private var logins:Map<String, String> = new Map();
	private var connections:Map<String, IConnection> = new Map();
	
	public function getLogin(connection:IConnection):Null<String>
	{
		if (logins.exists(connection.getContext().peerToString()))
			return logins[connection.getContext().peerToString()];
		else
			return null;
	}
	
	public function getConnection(l:String):Null<IConnection>
	{
		if (connections.exists(l))
			return connections[l];
		else
			return null;
	}
	
	public function sendPlPrData(c:IConnection)
	{
		var l = getLogin(c);
		if (l == null)
			return;

		var data:RoamData = 
		{
			player: PlayerdataManager.instance.cache.get(l), 
			record: PlayerdataManager.instance.getFourMostPlayedRecords(l)
		};

		c.send("PlayerProgressData", Json.stringify(data));
	}
	
	public function login(data:LoginPair, c:IConnection)
	{
		if (getLogin(c) == null && getConnection(data.login) == null)
			if (checkPassword(data))
			{
				PlayerdataManager.instance.loadPlayer(data.login);
				logins[c.getContext().peerToString()] = data.login;
				connections[data.login] = c;
				c.send("LoggedIn");
				Sys.println('(J/L) ${data.login} logged in');
				sendPlPrData(c);
			}
			else
				c.send("BadLogin");
		else
			c.send("AlreadyLogged");
	}
	
	public function logout(c:IConnection)
	{
		var peer:String = c.getContext().peerToString();
		if (!logins.exists(peer))
			return;
		
		var l:String = logins[peer];
		PlayerdataManager.instance.unloadPlayer(l);
		logins.remove(peer);
		connections.remove(l);
		Sys.println('(J/L) $l disconnected');
	}

	public function registerAndLogin(data:LoginPair, sender:IConnection) 
	{
		if (register(data, sender))
			login(data, sender);
	}
	
	private function register(pair:LoginPair, c:IConnection):Bool
	{
		if (pair.login.length < 2)
		{
			c.send("SmallLogin");
			return false;
		}

		if (getLogin(c) != null)
		{
			c.send("AlreadyLogged");
			return false;
		}
		
		var l = pair.login.toLowerCase();
		var listPath:String = Main.playersDir + "list.json";	
		var content:String = File.getContent(listPath);
		var list:Dynamic = Json.parse(content);
		
		if (Reflect.hasField(list, l))
		{
			c.send("AlreadyRegistered");
			return false;
		}
		
		Reflect.setField(list, l, Md5.encode(pair.password));
		File.saveContent(listPath, Json.stringify(list, null, "\t"));
		createPlayer(pair.login);
		Sys.println('(J/L) Registered ${pair.login}');
		return true;
	}

	private function createPlayer(login:String, ?element:Element = Lightning)
	{
		var l = login.toLowerCase();
		var path = Main.playersDir + l + "\\";
		FileSystem.createDirectory(path + "patterns\\");

		var str:String = File.getContent(Main.playersDir + "default.json");
		str = str.replace('dname', login);
		str = str.replace('delement', element.getName());
		str = str.replace('"dabp"', "" + GameRules.initialAbilityPoints);
		str = str.replace('"dattp"', "" + GameRules.initialAttributePoints);
		File.saveContent(path + l + ".json", str);
		generatePatternFiles(login, element);
	}

	private function generatePatternFiles(login:String, element:Element)
	{
		var path = Main.playersDir + login.toLowerCase() + "\\patterns\\";
		for (id in AbilityManager.trees.get(element).getAbilities())
		{
			var ab = AbilityManager.abilities.get(id);
			if (ab.danmakuType != null)
			{
				var abFolderPath = path + ab.id.getName() + "\\";
				FileSystem.createDirectory(abFolderPath);
				for (i in 1...4)
					File.saveContent(abFolderPath + i + ".json", "[]");
			}
		}
	}
	
	private function checkPassword(pair:LoginPair):Bool
	{
		var list = Json.parse(File.getContent(Main.playersDir + "list.json"));
		
		if (Reflect.hasField(list, pair.login.toLowerCase()))
			return Md5.encode(pair.password) == Reflect.field(list, pair.login.toLowerCase());
		else
			return false;
	}
	
	public function new() 
	{
		instance = this;
	}
	
}