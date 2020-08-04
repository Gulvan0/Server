package battle.struct;
import managers.AbilityManager;
import ID.AbilityID;
import battle.Ability;
import battle.Active;
import battle.Passive;
import battle.data.Passives.BattleEvent;
import battle.enums.AbilityType;
import hxassert.Assert;

/**
 * Ability wheel
 * @author Gulvan
 */
class Wheel 
{

	private var wheel:Array<Ability>;
	
	public var numOfSlots:Int;
	
	public function getlwArray():Array<LightweightAbility>
	{
		return [for (a in wheel) a.toLightweight()];
	}
	
	public function get(pos:Int):Ability
	{
		Assert.assert(pos >= 0 && pos <= 9);
		return wheel[pos];
	}

	public function getByID(id:AbilityID):Null<Ability>
	{
		for (ab in wheel)
			if (ab.id == id)
				return ab;
		return null;
	}
	
	public function getActive(pos:Int):Active
	{
		Assert.assert(pos >= 0 && pos <= 9);
		Assert.assert(wheel[pos].type != AbilityType.Passive); 
		return cast wheel[pos];
	}

	public function actives():Array<AbilityID>
	{
		var activeAbs:Array<Ability> = wheel.filter(ab->ab.isActive());
		var activeAbIDs:Array<AbilityID> = activeAbs.map(ab->ab.id);
		return activeAbIDs;
	}

	public function bhAbs():Array<AbilityID>
	{
		var activeAbs:Array<Ability> = wheel.filter(ab->ab.isBH());
		var activeAbIDs:Array<AbilityID> = activeAbs.map(ab->ab.id);
		return activeAbIDs;
	}

	public function auras():Array<Ability>
	{
		return wheel.filter(ab->(ab.type == Aura));
	}
	
	public function passives(?trigger:Null<BattleEvent>):Array<AbilityID>
	{
		return passiveAbs(trigger).map(ab->ab.id);
	}

	public function passiveAbs(?trigger:Null<BattleEvent>):Array<Ability>
	{
		var passiveAbs:Array<Ability> = wheel.filter(ab->!ab.isActive());
		if (trigger == null)
			passiveAbs = passiveAbs.filter(p->cast(p, Passive).reactsTo(trigger));
		return passiveAbs;
	}
	
	public function set(pos:Int, ability:Ability):Ability
	{
		Assert.assert(pos >= 0 && pos <= 9);
		return wheel[pos] = ability;
	}
	
	public function tick()
	{
		for (ability in wheel)
			if (!ability.checkEmpty() && ability.type != AbilityType.Passive)
				cast(ability, Active).tick();
	}
	
	public function new(pool:Array<AbilityID>, levels:Map<AbilityID, Int>, numOfSlots:Int) 
	{
		Assert.assert(pool.length <= numOfSlots && numOfSlots >= 8 && numOfSlots <= 10);
		
		this.wheel = new Array<Ability>();
		for (id in pool)
			if (id == AbilityID.EmptyAbility || id == AbilityID.LockAbility)
				this.wheel.push(new Ability(id, 0));
			else if (AbilityManager.abilities.get(id).type != AbilityType.Passive)
				this.wheel.push(new Active(id, levels.get(id)));
			else
				this.wheel.push(new Passive(id, levels.get(id)));
		for (i in pool.length...numOfSlots)
			this.wheel[i] = new Ability(EmptyAbility, 0);
		for (i in numOfSlots...10)
			this.wheel[i] = new Ability(LockAbility, 0);
		this.numOfSlots = numOfSlots;
	}
	
}