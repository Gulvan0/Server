package;

import managers.LoginManager;
import battle.Unit;
import hxassert.Assert;
import mphx.connection.IConnection;

/**
 * ...
 * @author gulvan
 */
class BattleRoom
{
	public var clients:Array<String> = new Array();
	
	public function add(login:String)
	{
		clients.push(login);
	}
	
	public function broadcast(event:String, ?data:Null<Dynamic>)
	{
		for (c in clients)
			LoginManager.instance.getConnection(c).send(event, data);
	}

	public function share(sourceLogin:String, event:String, ?data:Null<Dynamic>)
	{
		for (c in clients)
			if (c != sourceLogin)
				LoginManager.instance.getConnection(c).send(event, data);
	}
	
	public function player(unit:Unit):IConnection
	{
		Assert.assert(unit.isPlayer());
		return LoginManager.instance.getConnection(unit.id.getParameters()[0]);
	}
	
	public function new() 
	{
		
	}
	
}