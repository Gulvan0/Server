package battle;
import battle.enums.Team;
import ID.BuffID;
import battle.enums.Source;
import battle.struct.UPair;
import battle.struct.UnitCoords;

/**
 * @author Gulvan
 */
interface IMutableModel 
{
	public function changeHP(target:UnitCoords, caster:UnitCoords, dhp:Int, element:Element, source:Source):Void;
	public function changeMana(target:UnitCoords, caster:UnitCoords, dmana:Int, source:Source):Void;
	public function changeAlacrity(target:UnitCoords, caster:UnitCoords, dalac:Float, source:Source):Void;
	
	public function castBuff(id:BuffID, targetCoords:UnitCoords, casterCoords:UnitCoords, duration:Int, ?properties:Map<String, String>):Void;
	public function dispellBuffs(target:UnitCoords, ?elements:Array<Element>, ?count:Int):Void;

	public function summon(s:Summon, position:UnitCoords):Void;
	public function applyAura(aura:Aura):Void;
	
	public function getUnits():UPair<Unit>;
}