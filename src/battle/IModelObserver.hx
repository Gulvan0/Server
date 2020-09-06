package battle;
import ID.AbilityID;
import battle.enums.AbilityType;
import battle.enums.Source;

import battle.struct.UnitCoords;
import MathUtils.Point;
/**
 * @author Gulvan
 */
interface IModelObserver 
{
	public function hpUpdate(target:Unit, caster:Unit, dhp:Int, element:Element, crit:Bool, source:Source):Void;
	public function manaUpdate(target:Unit, dmana:Int, source:Source):Void;
	public function alacUpdate(unit:Unit, dalac:Float, source:Source):Void;
	public function shielded(target:UnitCoords, source:Source):Void;
	
	public function buffQueueUpdate(unit:UnitCoords, queue:Array<Buff>):Void;
	
	public function turn(current:Unit):Void;
	public function preTick(current:Unit):Void;
	public function tick(current:Unit):Void;
	public function pass(current:UnitCoords):Void;
	public function miss(target:UnitCoords, caster:UnitCoords, element:Element):Void;
	public function death(unit:UnitCoords):Void;
	
	public function abThrown(target:UnitCoords, caster:UnitCoords, id:AbilityID, type:AbilityType, element:Element):Void;
	public function abStriked(target:UnitCoords, caster:UnitCoords, ab:Ability, pattern:String):Void;
}