package battle;
import battle.struct.UnitCoords;
import battle.struct.Wheel;

/**
 * @author Gulvan
 */
interface IInteractiveModel 
{
	public function getState():Model;
	public function getPersonal(login:String):Wheel;
	public function useRequest(login:String, abilityPos:Int, targetCoords:UnitCoords):Void;
	public function skipTurn(login:String):Void;
	public function quit(login:String):Void;
}