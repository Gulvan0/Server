package battle;
import ID.BuffID;
import battle.data.Buffs;
import battle.data.Passives.BattleEvent;
import battle.enums.BuffMode;
import Element;
import battle.struct.UnitCoords;

class LightweightBuff
{
	public var id:BuffID;
	public var name:String;
	public var description:String;
	public var element:Element;
	
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
	public var isOverTime(default, null):Bool;
	public var isStackable(default, null):Bool;
	public var triggers(default, null):Array<BattleEvent>;
	
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
		if (isOverTime)
			act(BuffMode.OverTime);
		duration--;
		
		return (duration == 0)? true : false;
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
		Buffs.useBuff(model, id, owner, caster, mode);
	}
	
	public function new(m:Model, id:BuffID, duration:Int, target:UnitCoords, caster:UnitCoords) 
	{
		this.model = m;
		this.id = id;
		//TODO:Fill
		/*this.name = XMLUtils.parseBuff(id, "name", "");
		this.description = XMLUtils.parseBuff(id, "description", "");
		this.element = XMLUtils.parseBuff(id, "element", Element);
		this.isOverTime = XMLUtils.parseBuff(id, "isOverTime", true);
		this.isStackable = XMLUtils.parseBuff(id, "isStackable", true);
		this.triggers = XMLUtils.parseTriggers(id); */
		
		this.owner = target;
		this.caster = caster;
		
		this.duration = duration;
	}
	
}