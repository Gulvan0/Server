package battle.struct;
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
	
	public function getActive(pos:Int):Active
	{
		Assert.assert(pos >= 0 && pos <= 9);
		Assert.assert(wheel[pos].type != AbilityType.Passive); 
		return cast wheel[pos];
	}
	
	public function passives(?trigger:Null<BattleEvent>):Array<AbilityID>
	{
		var res:Array<AbilityID> = [];
		for (ab in wheel)
			if (ab.type == AbilityType.Passive)
			{
				var p:Passive = cast ab;
				if (trigger == null || p.reactsTo(trigger))
					res.push(p.id);
			}
		return res;
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
	
	public function new(pool:Array<AbilityID>, numOfSlots:Int) 
	{
		Assert.assert(pool.length <= numOfSlots && numOfSlots >= 8 && numOfSlots <= 10);
		
		this.wheel = new Array<Ability>();
		for (id in pool)
			if (id == AbilityID.EmptyAbility || id == AbilityID.LockAbility)
				this.wheel.push(new Ability(id));
			/*else if (XMLUtils.parseAbility(id, "type", AbilityType) == AbilityType.Passive)
				this.wheel.push(new Active(id));*///TODO: Rewrite
			else
				this.wheel.push(new Passive(id));
		for (i in pool.length...numOfSlots)
			this.wheel[i] = new Ability(AbilityID.EmptyAbility);
		for (i in numOfSlots...10)
			this.wheel[i] = new Ability(AbilityID.LockAbility);
		this.numOfSlots = numOfSlots;
	}
	
}