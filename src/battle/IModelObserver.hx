package battle;
import battle.struct.EntityCoords;
import ID.SummonID;
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
	public function shielded(target:EntityCoords, source:Source):Void;
	
	public function buffQueueUpdate(unit:UnitCoords, queue:Array<Buff>):Void;
	
	public function turn(current:Unit):Void;
	public function preTick(current:Unit):Void;
	public function tick(current:Unit):Void;
	public function pass(current:UnitCoords):Void;
	public function miss(target:EntityCoords, caster:UnitCoords, element:Element):Void;
	public function death(coords:EntityCoords):Void;
	
	public function abThrown(target:EntityCoords, caster:UnitCoords, id:AbilityID, type:AbilityType, element:Element):Void;
	public function abStriked(target:EntityCoords, caster:UnitCoords, ab:Active, pattern:String):Void;

	public function auraApplied(owner:EntityCoords, id:AbilityID):Void;
	public function aurasRemoved(owner:EntityCoords):Void;
	public function summonAppeared(position:EntityCoords, id:SummonID, maxHP:Int):Void;
}