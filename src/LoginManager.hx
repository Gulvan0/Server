package;
import haxe.crypto.Md5;
import mphx.connection.IConnection;
import Main.LoginPair;
import neko.Lib;
import sys.io.File;

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
		sl.open("playerdata\\" + getLogin(c) + ".xml");
		c.send("PlayerProgressData", sl.xml.toString());
		sl.close();
	}
	
	public function login(data:LoginPair, c:IConnection)
	{
		if (getLogin(c) == null)
			if (checkPassword(data))
			{
				logins[c.getContext().peerToString()] = data.login;
				connections[data.login] = c;
				c.send("LoggedIn");
				Lib.println('(J/L) ${data.login} logged in');
				sendPlPrData(c);
			}
			else
				c.send("BadLogin");
		else
			c.send("AlreadyLogged");
	}
	
	public function logout(c:IConnection)
	{
		if (!logins.exists(c.getContext().peerToString()))
			return;
		
		var l:String = logins[c.getContext().peerToString()];
		logins.remove(c.getContext().peerToString());
		connections.remove(l);
		Lib.println('(J/L) $l disconnected');
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
			if (p.get("login") == pair.login)
			{
				c.send("AlreadyRegistered");
				return false;
			}
		
		if (pair.login.length >= 2)
		{
			File.saveContent(loginPath(), content + "\n<player login=\"" + pair.login + "\">" + Md5.encode(pair.password) + "</player>");
			Lib.println('(Join) Registered ${pair.login}');
			return true;
		}
		else
		{
			c.send("SmallLogin");
			return false;	
		}
	}
	
	private function checkPassword(pair:LoginPair):Bool
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
		return Main.playersDir() + "playerslist.xml";
	}
	
	public function new() 
	{
		
	}
	
}