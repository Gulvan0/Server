package battle;
import battle.enums.StrikeType;
import battle.Buff;
import battle.struct.UnitCoords;
import battle.enums.Source;
import battle.Unit;

/**
 * ...
 * @author ...
 */
class EventSender implements IModelObserver 
{
	
	private var room:BattleRoom;
	
	public function new(room:BattleRoom) 
	{
		this.room = room;
	}
	
	
	/* INTERFACE battle.IModelObserver */
	
	public function hpUpdate(target:Unit, caster:Unit, dhp:Int, element:Element, crit:Bool, source:Source):Void 
	{
		room.broadcast("HPUpdate", {target: UnitCoords.get(target), delta: dhp, newV: target.hpPool.value, element: element, crit: crit, fromAbility: source == Source.Ability});
	}
	
	public function manaUpdate(target:Unit, dmana:Int, source:Source):Void 
	{
		room.broadcast("ManaUpdate", {target: UnitCoords.get(target), delta: dmana, newV: target.manaPool.value});
	}
	
	public function alacUpdate(unit:Unit, dalac:Float, source:Source):Void 
	{
		room.broadcast("AlacrityUpdate", {target: UnitCoords.get(unit), delta: dalac, newV: unit.alacrityPool.value});
	}
	
	public function buffQueueUpdate(unit:UnitCoords, queue:Array<Buff>):Void 
	{
		room.broadcast("BuffQueueUpdate", {target: unit, queue: [for (b in queue) b.toLightweight()]});
	}
	
	public function preTick(current:Unit):Void 
	{
		
	}
	
	public function tick(current:Unit):Void 
	{
		room.player(current).send("Tick");
	}
	
	public function miss(target:UnitCoords, element:Element):Void 
	{
		room.broadcast("Miss", {target: target, element: element});
	}
	
	public function death(unit:UnitCoords):Void 
	{
		room.broadcast("Death", {target: unit});
	}
	
	public function abThrown(target:UnitCoords, caster:UnitCoords, id:ID, type:StrikeType, element:Element):Void 
	{
		room.broadcast("Thrown", {target: target, caster: caster, id: id, type: type, element: element});
	}
	
	public function abStriked(target:UnitCoords, caster:UnitCoords, id:ID, type:StrikeType, element:Element):Void 
	{
		room.broadcast("Strike", {target: target, caster: caster, id: id, type: type, element: element});
	}
	
}