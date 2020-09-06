package battle;
import battle.Model.Particle;
import MathUtils.Point;

import ID.AbilityID;
import battle.Buff;
import battle.struct.UnitCoords;
import battle.enums.Source;
import battle.Unit;
import json2object.JsonWriter;
import battle.Model.Pattern;
import battle.enums.AbilityType;

typedef HPupdate = {target:UnitCoords, delta:Int, newV:Int, element:Element, crit:Bool, source:Source}
typedef ManaUpdate = {target:UnitCoords, delta:Int, newV:Int}
typedef AlacUpdate = {target:UnitCoords, delta:Float, newV:Float}
typedef ShieldDetails = {target:UnitCoords, source:Source}
typedef MissDetails = {target:UnitCoords, element:Element}
typedef DeathDetails = {target:UnitCoords}
typedef ThrowDetails = {target:UnitCoords, caster:UnitCoords, id:AbilityID, type:AbilityType, element:Element}
typedef StrikeDetails = {target:UnitCoords, caster:UnitCoords, id:AbilityID, level:Int, type:AbilityType, element:Element, pattern:String}
typedef BuffQueueUpdate = {target:UnitCoords, queue:Array<LightweightBuff>}

/**
 * Broadcasts battle events
 * @author gulvan
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
		var writer = new JsonWriter<HPupdate>();
		room.broadcast("HPUpdate", writer.write({target: UnitCoords.get(target), delta: dhp, newV: target.hpPool.value, element: element, crit: crit, source: source}));
	}
	
	public function manaUpdate(target:Unit, dmana:Int, source:Source):Void 
	{
		var writer = new JsonWriter<ManaUpdate>();
		room.broadcast("ManaUpdate", writer.write({target: UnitCoords.get(target), delta: dmana, newV: target.manaPool.value}));
	}
	
	public function alacUpdate(unit:Unit, dalac:Float, source:Source):Void 
	{
		var writer = new JsonWriter<AlacUpdate>();
		room.broadcast("AlacrityUpdate", writer.write({target: UnitCoords.get(unit), delta: dalac, newV: unit.alacrityPool.value}));
	}

	public function shielded(target:UnitCoords, source:Source)
	{
		var writer = new JsonWriter<ShieldDetails>();
		room.broadcast("Shielded", writer.write({target: target, source: source}));
	}
	
	public function buffQueueUpdate(unit:UnitCoords, queue:Array<Buff>):Void 
	{
		var writer = new JsonWriter<BuffQueueUpdate>();
		room.broadcast("BuffQueueUpdate", writer.write({target: unit, queue: [for (b in queue) b.toLightweight()]}));
	}
	
	public function preTick(current:Unit):Void 
	{
		
	}

	public function turn(current:Unit):Void 
	{
		room.broadcast("Turn", UnitCoords.get(current));
	}
	
	public function tick(current:Unit):Void 
	{
		room.broadcast("Tick", UnitCoords.get(current));
	}

	public function pass(current:UnitCoords):Void
	{
		room.broadcast("Pass", current);
	}
	
	public function miss(target:UnitCoords, caster:UnitCoords, element:Element):Void 
	{
		var writer = new JsonWriter<MissDetails>();
		room.broadcast("Miss", writer.write({target: target, element: element}));
	}
	
	public function death(unit:UnitCoords):Void 
	{
		var writer = new JsonWriter<DeathDetails>();
		room.broadcast("Death", writer.write({target: unit}));
	}
	
	public function abThrown(target:UnitCoords, caster:UnitCoords, id:AbilityID, type:AbilityType, element:Element):Void 
	{
		var writer = new JsonWriter<ThrowDetails>();
		room.broadcast("Throw", writer.write({target: target, caster: caster, id: id, type: type, element: element}));
	}
	
	public function abStriked(target:UnitCoords, caster:UnitCoords, ab:Ability, pattern:String):Void 
	{
		var writer = new JsonWriter<StrikeDetails>();
		room.broadcast("Strike", writer.write({target: target, caster: caster, id: ab.id, level: ab.level, type: ab.type, element: ab.element, pattern: pattern}));
	}
	
}