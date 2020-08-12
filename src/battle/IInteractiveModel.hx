package battle;
import battle.struct.UnitCoords;
import ID.AbilityID;

/**
 * @author Gulvan
 */
interface IInteractiveModel 
{
	public function start():Void;
	public function getBattleData(login:String):String;
	public function selectPattern(login:String, ability:AbilityID, ptnPos:Int):Void;
	public function useRequest(login:String, abilityPos:Int, targetCoords:UnitCoords):Void;
	public function skipTurn(login:String):Void;
	public function quit(login:String):Void;
	public function playerCollided(login:String):Void;
	public function playerBHFinished(login:String):Void;
}