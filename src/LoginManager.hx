package;
import sys.io.FileOutput;
import sys.FileSystem;
import haxe.crypto.Md5;
import mphx.connection.IConnection;
import Main.LoginPair;
import sys.io.File;
using StringTools;

/**
 * ...
 * @author gulvan
 */
class LoginManager 
{
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
		var sl:SaveLoad = new SaveLoad();
		sl.open("playerdata\\" + getLogin(c).toLowerCase() + ".xml");
		var allData:String = sl.xml.toString();
		var ereg:EReg = new EReg("<pattern.+?</pattern>", "");
		var eregBlank:EReg = new EReg("[\\f\\n\\r\\t\\v]+", "");
		var valuableData:String = allData;
		while (eregBlank.match(valuableData))
			valuableData = eregBlank.replace(valuableData, "");
		while (ereg.match(valuableData))
			valuableData = ereg.replace(valuableData, "");
		c.send("PlayerProgressData", valuableData);
		sl.close();
	}
	
	public function login(data:LoginPair, c:IConnection)
	{
		if (getLogin(c) == null && getConnection(data.login) == null)
			if (checkPassword(data))
			{
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
		logins.remove(peer);
		connections.remove(l);
		Sys.println('(J/L) $l disconnected');
	}
	
	public function register(pair:LoginPair, c:IConnection):Bool
	{
		if (getLogin(c) != null)
		{
			c.send("AlreadyLogged");
			return false;
		}
			
		var content:String = File.getContent(loginPath());
		for (p in Xml.parse(content).elementsNamed("player"))
			if (p.get("login").toLowerCase() == pair.login.toLowerCase())
			{
				c.send("AlreadyRegistered");
				return false;
			}
		
		if (pair.login.length >= 2)
		{
			File.saveContent(loginPath(), content + "\n<player login=\"" + pair.login.toLowerCase() + "\">" + Md5.encode(pair.password) + "</player>");
			createPlayer(pair.login);
			Sys.println('(J/L) Registered ${pair.login}');
			return true;
		}
		else
		{
			c.send("SmallLogin");
			return false;	
		}
	}

	private function createPlayer(login:String)
	{
		var str:String = File.getContent(Main.playersDir() + "d.xml");
		str = strReplace(str, "dname", login);
		str = strReplace(str, "dabp", "" + GameRules.initialAbilityPoints);
		str = strReplace(str, "dattp", "" + GameRules.initialAttributePoints);
		var fo:FileOutput = File.write(Main.playersDir() + login.toLowerCase() + ".xml");
		fo.writeString(str);
		fo.close();
	}
	
	private function checkPassword(pair:LoginPair):Bool
	{
		var xml:Xml = Xml.parse(File.getContent(loginPath()));
		
		for (p in xml.elementsNamed("player"))
		{
			if (p.get("login") == pair.login.toLowerCase())
				return Md5.encode(pair.password) == p.firstChild().nodeValue;
		}
		
		return false;
	}
	
	private static function loginPath():String
	{
		return Main.playersDir() + "playerslist.xml";
	}

	private static function strReplace(str:String, sub:String, by:String):String
	{
		var a:Array<String> = str.split(sub);
		str = a[0];
		for (i in 1...a.length)
			str += by + a[i];
		return str;
	}
	
	public function new() 
	{
		
	}
	
}