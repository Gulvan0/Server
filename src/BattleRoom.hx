package;

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
	
	public function new() 
	{
		super();
		
	}
	
}