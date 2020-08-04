package battle;
import managers.BuffManager;
import ID.BuffID;
import battle.data.Buffs;
import battle.data.Passives.BattleEvent;
import battle.enums.BuffMode;
import Element;
import battle.struct.UnitCoords;
using Lambda;

class LightweightBuff
{
	public var id:BuffID;
	public var name:String;
	public var description:String;
	public var element:Element;
	public var properties:Map<String, String>;
	
	public var duration:Int;
	
	public function new() 
	{
		
	}
}

/**
 * model OF buff IN battle
 * @author Gulvan
 */
class Buff
{
	private var model:Model;
	
	public var id(default, null):BuffID;
	public var name(default, null):String;
	public var description(default, null):String;
	public var element(default, null):Element;
	public var flags(default, null):Array<BuffFlag>;
	public var triggers(default, null):Array<BattleEvent>;
	public var properties(default, null):Map<String, String>;
	
	public var owner(default, null):UnitCoords;
	public var caster(default, null):UnitCoords;
	
	public var duration(default, null):Int;
	
	public function toLightweight():LightweightBuff
	{
		var lb:LightweightBuff = new LightweightBuff();
		lb.id = id;
		lb.name = name;
		lb.description = description;
		lb.element = element;
		lb.duration = duration;
		lb.properties = properties;
		return lb;
	}
	
	public function reactsTo(e:BattleEvent):Bool
	{
		for (event in triggers)
			if (e == event)
				return true;
		return false;
	}
	
	public function tickAndCheckEnded():Bool
	{
		overtimeWithoutTick();
		duration--;
		
		return (duration == 0)? true : false;
	}

	public function overtimeWithoutTick()
	{
		if (flags.has(BuffFlag.Overtime))
			act(BuffMode.OverTime);
	}
	
	public function onCast()
	{
		act(BuffMode.Cast);
	}
	
	public function onEnd()
	{
		act(BuffMode.End);
	}
	
	private function act(mode:BuffMode)
	{
		Buffs.useBuff(model, id, owner, caster, mode, properties);
	}
	
	public function new(m:Model, id:BuffID, duration:Int, target:UnitCoords, caster:UnitCoords, ?properties:Map<String, String>) 
	{
		var buffObj = BuffManager.buffs.get(id);
		this.model = m;
		this.id = id;
		this.properties = properties == null? [] : properties;
		this.name = buffObj.name;
		this.description = buffObj.rawDesc;
		this.element = buffObj.element;
		this.flags = buffObj.flags;
		this.triggers = buffObj.triggers;
		
		this.owner = target;
		this.caster = caster;
		
		this.duration = duration;
	}
	
}