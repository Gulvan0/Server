package battle;
import managers.AbilityManager;
import battle.struct.EntityCoords;
import ID.SummonID;
import ID.AbilityID;
import battle.Model.Pattern;
import MathUtils.Point;
import battle.data.Buffs;
import battle.data.Passives;
import battle.enums.AbilityType;
import battle.Buff;
import battle.enums.BuffMode;
import battle.struct.UnitCoords;
import battle.enums.Source;
import battle.Unit;

class EffectData
{
	public var target:Null<Unit>;
	public var caster:Null<Unit>;
	public var delta:Null<Float>;
	public var element:Null<Element>;
	public var source:Null<Source>;
	public function new(target:Null<Unit>, caster:Null<Unit>, delta:Null<Float>, element:Null<Element>, source:Null<Source>)
	{
		this.target = target;
		this.caster = caster;
		this.delta = delta;
		this.element = element;
		this.source = source;
	}
}

/**
 * An observer that forces passives to react on battle events
 * @author Gulvan
 */
class EffectHandler implements IModelObserver
{
	
	private var model:IMutableModel;
	private var flag:Bool = true;
	
	public function init(m:IMutableModel)
	{
		if (flag)
		{
			model = m;
			flag = false;
		}
		else
			throw "Attempt to re-init";
	}
	
	private function procAbilities(e:BattleEvent, unit:Unit, data:EffectData)
	{
		for (ab in unit.wheel.abilities)
			if (AbilityManager.passives.exists(ab))
				if (AbilityManager.reactsTo(ab, e))
					Passives.handle(model, AbilityManager.passives.get(ab).id, unit.wheel.levelByID(ab), e, data);
	}
	
	private function procBuffs(e:BattleEvent, unit:Unit, ?data:EffectData)
	{
		for (buff in unit.buffQueue.getTriggering(e))
			Buffs.useBuff(model, buff.id, buff.owner, buff.caster, BuffMode.Proc, buff.properties, data, e);
	}
	
	/* INTERFACE battle.IModelObserver */
	
	public function hpUpdate(target:Unit, caster:Unit, dhp:Int, element:Element, crit:Bool, source:Source):Void 
	{
		var data:EffectData = new EffectData(target, caster, dhp, element, source);
		
		procAbilities(BattleEvent.HPUpdate, target, data);
		procBuffs(BattleEvent.HPUpdate, target, data);
		if (crit && !target.same(caster))
		{
			procAbilities(BattleEvent.OutgoingCrit, caster, data);
			procBuffs(BattleEvent.OutgoingCrit, caster, data);
		}
	}
	
	public function manaUpdate(target:Unit, dmana:Int, source:Source):Void 
	{
		var data:EffectData = new EffectData(target, null, dmana, null, source);
		
		procAbilities(BattleEvent.ManaUpdate, target, data);
		procBuffs(BattleEvent.ManaUpdate, target, data);
	}
	
	public function alacUpdate(unit:Unit, dalac:Float, source:Source):Void 
	{
		var data:EffectData = new EffectData(unit, null, dalac, null, source);
		
		procAbilities(BattleEvent.AlacUpdate, unit, data);
		procBuffs(BattleEvent.AlacUpdate, unit, data);
	}

	public function shielded(target:EntityCoords, summon:Bool, source:Source)
	{
		
	}
	
	public function preTick(current:Unit):Void
	{
		//no action
	}

	public function turn(current:Unit):Void
	{
		//no action
	}

	public function pass(current:UnitCoords):Void
	{
		//no action
	}
	
	public function tick(current:Unit):Void 
	{
		var data:EffectData = new EffectData(current, null, null, null, null);
		
		procAbilities(BattleEvent.Tick, current, data);
		procBuffs(BattleEvent.Tick, current, data);
	}
	
	public function miss(target:EntityCoords, caster:UnitCoords, element:Element):Void 
	{
		var t:Unit = getUnit(target.nearbyUnit());
		var c:Unit = getUnit(caster.nearbyUnit());
		var data:EffectData = new EffectData(t, c, null, element, null);
		
		if (t.team != c.team)
		{
			if (!target.summon)
			{
				procAbilities(BattleEvent.IncomingMiss, t, data);
				procBuffs(BattleEvent.IncomingMiss, t, data);
			}
			procAbilities(BattleEvent.OutgoingMiss, c, data);
			procBuffs(BattleEvent.OutgoingMiss, c, data);
		}
	}
	
	public function death(coords:EntityCoords):Void 
	{
		if (coords.summon)
			return;

		var data:EffectData = new EffectData(getUnit(coords.nearbyUnit()), null, null, null, null);
		
		for (u in model.getUnits())
		{
			procAbilities(BattleEvent.Death, u, data);
			procBuffs(BattleEvent.Death, u, data);
		}
	}
	
	public function abStriked(target:EntityCoords, caster:UnitCoords, ab:Active, pattern:String):Void 
	{
		var t:Unit = getUnit(target);
		var c:Unit = getUnit(caster);
		var data:EffectData = new EffectData(t, c, null, ab.element, null);
		
		if (t.team != c.team && !target.summon)
		{
			procAbilities(BattleEvent.IncomingStrike, t, data);
			procBuffs(BattleEvent.IncomingStrike, t, data);
			procAbilities(BattleEvent.OutgoingStrike, c, data);
			procBuffs(BattleEvent.OutgoingStrike, c, data);
		}
	}
	
	public function abThrown(target:EntityCoords, caster:UnitCoords, id:AbilityID, type:AbilityType, element:Element):Void 
	{
		//no action - for now
	}
	
	public function buffQueueUpdate(unit:UnitCoords, queue:Array<Buff>):Void 
	{
		//no action
	}

	public function auraApplied(owner:UnitCoords, id:AbilityID):Void
	{

	}

	public function auraRemoved(owner:UnitCoords):Void
	{

	}
	
	public function summonAppeared(position:EntityCoords, id:SummonID, maxHP:Int):Void
	{

	}
	
	
	//--------------------------------------------------------------------
	
	private function getUnit(coords:UnitCoords):Unit
	{
		return model.getUnits().get(coords);
	}
	
	public function new() 
	{
		
	}
	
}