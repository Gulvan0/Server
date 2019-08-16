package battle;
import MathUtils.Point;
import battle.enums.StrikeType;
import battle.Buff;
import battle.struct.UnitCoords;
import battle.enums.Source;
import battle.Unit;
import json2object.JsonWriter;

typedef HPupdate = {target:UnitCoords, delta:Int, newV:Int, element:Element, crit:Bool, source:Source}
typedef ManaUpdate = {target:UnitCoords, delta:Int, newV:Int}
typedef AlacUpdate = {target:UnitCoords, delta:Float, newV:Float}
typedef MissDetails = {target:UnitCoords, element:Element}
typedef DeathDetails = {target:UnitCoords}
typedef ThrowDetails = {target:UnitCoords, caster:UnitCoords, id:ID, type:StrikeType, element:Element}
typedef StrikeDetails = {target:UnitCoords, caster:UnitCoords, id:ID, type:StrikeType, element:Element, pattern:Array<Array<String>>, trajectory:Array<Array<String>>}
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
		trace(writer.write({target: UnitCoords.get(unit), delta: dalac, newV: unit.alacrityPool.value}));
		room.broadcast("AlacrityUpdate", writer.write({target: UnitCoords.get(unit), delta: dalac, newV: unit.alacrityPool.value}));
		trace("ok");
	}
	
	public function buffQueueUpdate(unit:UnitCoords, queue:Array<Buff>):Void 
	{
		var writer = new JsonWriter<BuffQueueUpdate>();
		room.broadcast("BuffQueueUpdate", writer.write({target: unit, queue: [for (b in queue) b.toLightweight()]}));
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
		var writer = new JsonWriter<MissDetails>();
		room.broadcast("Miss", writer.write({target: target, element: element}));
	}
	
	public function death(unit:UnitCoords):Void 
	{
		var writer = new JsonWriter<DeathDetails>();
		room.broadcast("Death", writer.write({target: unit}));
	}
	
	public function abThrown(target:UnitCoords, caster:UnitCoords, id:ID, type:StrikeType, element:Element):Void 
	{
		var writer = new JsonWriter<ThrowDetails>();
		room.broadcast("Strike", writer.write({target: target, caster: caster, id: id, type: type, element: element}));
	}
	
	public function abStriked(target:UnitCoords, caster:UnitCoords, id:ID, type:StrikeType, element:Element, pattern:Array<Array<Point>>, trajectory:Array<Array<Point>>):Void 
	{
		var writer = new JsonWriter<StrikeDetails>();
		var sPattern:Array<Array<String>> = [for (g in pattern) [for (p in g) p.x + "|" + p.y]];
		var sTrajectory:Array<Array<String>> = [for (g in trajectory) [for (p in g) p.x + "|" + p.y]];
		room.broadcast("Strike", writer.write({target: target, caster: caster, id: id, type: type, element: element, pattern: sPattern, trajectory:sTrajectory}));
	}
	
}