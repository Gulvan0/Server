package battle;
import battle.struct.UnitCoords;

/**
 * @author Gulvan
 */
interface IInteractiveModel 
{
	public function start():Void;
	public function getInitialState():Dynamic;
	public function getPersonal(login:String):Dynamic;
	public function useRequest(login:String, abilityPos:Int, targetCoords:UnitCoords):Void;
	public function skipTurn(login:String):Void;
	public function quit(login:String):Void;
}