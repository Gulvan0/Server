package;

import battle.Unit;
import hxassert.Assert;
import mphx.server.room.Room;
import mphx.connection.IConnection;

/**
 * ...
 * @author gulvan
 */
class BattleRoom extends Room 
{
	public var clientMap:Map<String, IConnection> = new Map();
	
	public function map(login:String, client:IConnection)
	{
		clientMap.remove(client.getContext().peerToString());
	}
	
	public function player(unit:Unit):IConnection
	{
		Assert.assert(unit.isPlayer());
		return clientMap[unit.id.getParameters()[0]];
	}
	
	public function new() 
	{
		super();
	}
	
}