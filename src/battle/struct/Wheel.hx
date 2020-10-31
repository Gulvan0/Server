package battle.struct;
import battle.data.Abilities;
import managers.AbilityManager;
import ID.AbilityID;
import battle.Active;
import battle.enums.AbilityType;
import hxassert.Assert;
using Lambda;

class LightweightAbility
{
	public var id:AbilityID;
	public var level:Int;
	public var patterns:Array<String>;
}

/**
 * Ability wheel
 * @author Gulvan
 */
class Wheel 
{
	public var abilities:Array<AbilityID>;
	public var levels:Array<Int>;
	public var actives:Map<AbilityID, Active>;
	
	public var numOfSlots:Int;
	
	public function getlwArray(patterns:Map<AbilityID, Array<String>>):Array<LightweightAbility>
	{
		var array:Array<LightweightAbility> = [];
		for (i in 0...numOfSlots)
		{
			var ab = new LightweightAbility();
			ab.id = abilities[i];
			ab.level = levels[i];
			ab.patterns = patterns.get(a.id);
		}
		return array;
	}

	public function auraIndexes():Array<Int>
	{
		var res = [];
		for (i in 0...abilities.length)
			if (AbilityManager.abilities.get(abilities[i]).type == Aura)
				res.push(i);
		return res;
	}

	public function levelByID(id:AbilityID):Null<Int>
	{
		var i = abilities.indexOf(id);
		return i == -1? null : levels[i];
	}
	
	public function tick()
	{
		for (ability in actives)
			ability.tick();
	}
	
	public function new(pool:Array<AbilityID>, levels:Map<AbilityID, Int>, numOfSlots:Int) 
	{
		Assert.assert(pool.length <= numOfSlots && numOfSlots >= 8 && numOfSlots <= 10);
		
		this.abilities = pool.copy();
		for (i in pool.length...numOfSlots)
			this.abilities[i] = EmptyAbility;
		levels[EmptyAbility] = 0;
		this.levels = pool.map(id->levels[id]);
		this.numOfSlots = numOfSlots;
	}
	
}