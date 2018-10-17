package battle;
import battle.struct.UnitCoords;

/**
 * @author Gulvan
 */
interface IInteractiveModel 
{
	public function useRequest(peerID:Int, abilityPos:Int, targetCoords:UnitCoords):Void;
	public function skipTurn(peerID:Int):Void;
	public function quit(peerID:Int):Void;
}