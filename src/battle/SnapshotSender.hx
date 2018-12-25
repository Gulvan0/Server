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
class SnapshotSender implements IModelObserver 
{
	
	private var room:BattleRoom;
	
	public function new(room:BattleRoom) 
	{
		this.room = room;
	}
	
	
	/* INTERFACE battle.IModelObserver */
	
	public function hpUpdate(target:Unit, caster:Unit, dhp:Int, element:Element, crit:Bool, source:Source):Void 
	{
		room.broadcast("HPUpdate", {target: UnitCoords.get(target), delta: dhp, element: element, crit: crit});
	}
	
	public function manaUpdate(target:Unit, dmana:Int, source:Source):Void 
	{
		room.broadcast("ManaUpdate", {target: UnitCoords.get(target), delta: dmana});
	}
	
	public function alacUpdate(unit:Unit, dalac:Float, source:Source):Void 
	{
		room.broadcast("AlacrityUpdate", {target: UnitCoords.get(unit), delta: dalac});
	}
	
	public function buffQueueUpdate(unit:UnitCoords, queue:Array<Buff>):Void 
	{
		room.broadcast("BuffQueueUpdate", {target: unit, queue: queue});
	}
	
	public function preTick(current:Unit):Void 
	{
		
	}
	
	public function tick(current:Unit):Void 
	{
		room.broadcast("Tick", {target: UnitCoords.get(current)});
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
		room.broadcast("Throw", {target: target, caster: caster, id: id, type: type, element: element});
	}
	
	public function abStriked(target:UnitCoords, caster:UnitCoords, id:ID, type:StrikeType, element:Element):Void 
	{
		room.broadcast("Strike", {target: target, caster: caster, id: id, type: type, element: element});
	}
	
}