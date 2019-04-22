package;

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
			Main.loginManager.getConnection(c).send(event, data);
	}
	
	public function player(unit:Unit):IConnection
	{
		Assert.assert(unit.isPlayer());
		return Main.loginManager.getConnection(unit.id.getParameters()[0]);
	}
	
	public function new() 
	{
		
	}
	
}