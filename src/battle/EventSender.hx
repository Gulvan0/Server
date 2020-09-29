package battle;
import ID.SummonID;
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
typedef ShieldDetails = {target:UnitCoords, summon:Bool, source:Source}
typedef MissDetails = {target:UnitCoords, summon:Bool, element:Element}
typedef DeathDetails = {target:UnitCoords}
typedef ThrowDetails = {target:UnitCoords, summon:Bool, caster:UnitCoords, id:AbilityID, type:AbilityType, element:Element}
typedef StrikeDetails = {target:UnitCoords, summon:Bool, caster:UnitCoords, id:AbilityID, level:Int, type:AbilityType, element:Element, pattern:String}
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

	public function shielded(target:UnitCoords, summon:Bool, source:Source)
	{
		var writer = new JsonWriter<ShieldDetails>();
		room.broadcast("Shielded", writer.write({target: target, summon: summon, source: source}));
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
	
	public function miss(target:UnitCoords, summon:Bool, caster:UnitCoords, element:Element):Void 
	{
		var writer = new JsonWriter<MissDetails>();
		room.broadcast("Miss", writer.write({target: target, summon: summon, element: element}));
	}
	
	public function death(unit:UnitCoords):Void 
	{
		var writer = new JsonWriter<DeathDetails>();
		room.broadcast("Death", writer.write({target: unit}));
	}
	
	public function abThrown(target:UnitCoords, summon:Bool, caster:UnitCoords, id:AbilityID, type:AbilityType, element:Element):Void 
	{
		var writer = new JsonWriter<ThrowDetails>();
		room.broadcast("Throw", writer.write({target: target, summon: summon, caster: caster, id: id, type: type, element: element}));
	}
	
	public function abStriked(target:UnitCoords, summon:Bool, caster:UnitCoords, ab:Ability, pattern:String):Void 
	{
		var writer = new JsonWriter<StrikeDetails>();
		room.broadcast("Strike", writer.write({target: target, summon: summon, caster: caster, id: ab.id, level: ab.level, type: ab.type, element: ab.element, pattern: pattern}));
	}

	public function auraApplied(owner:UnitCoords, id:AbilityID):Void
	{
		room.broadcast("AuraApplied", {owner: owner, id: id.getName()});
	}

	public function auraRemoved(owner:UnitCoords, id:AbilityID):Void
	{
		room.broadcast("AuraRemoved", {owner: owner, id: id.getName()});
	}
	
	public function summonAppeared(position:UnitCoords, id:SummonID):Void
	{
		room.broadcast("SummonAppeared", {position: position, id: id.getName()});
	}
	
	public function summonDead(position:UnitCoords):Void
	{
		room.broadcast("SummonDead", {position: position});
	}
	
}