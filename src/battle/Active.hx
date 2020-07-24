package battle;
import ID.AbilityID;
import battle.Ability.LightweightAbility;
import battle.enums.AbilityTarget;
import managers.AbilityManager;

import battle.enums.UnitType;
import battle.struct.Countdown;

/**
 * Active ability
 * @author Gulvan
 */
class Active extends Ability 
{
	public var possibleTarget(default, null):AbilityTarget;
	public var aoe(default, null):Bool;
	
	private var _cooldown:Countdown;
	public var cooldown(get, null):Int;
	public var maxCooldown(get, null):Int;
	public var manacost(default, null):Int;
	
	public override function toLightweight():LightweightAbility
	{
		var la:LightweightAbility = new LightweightAbility();
		la.id = id;
		la.name = name;
		la.type = type;
		la.element = element;
		la.level = level;
		
		la.cooldown = maxCooldown;
		la.delay = cooldown;
		la.manacost = manacost;
		la.target = possibleTarget;
		
		return la;
	}
	
	public function putOnCooldown()
	{
		_cooldown.value = _cooldown.keyValue;
	}
	
	public function tick()
	{
		if (checkOnCooldown())
			_cooldown.value--;
	}
	
	public function new(id:AbilityID, level:Int) 
	{
		super(id, level);
		
		if (!checkEmpty())
		{
			var ab = AbilityManager.abilities.get(id);
			this._cooldown = new Countdown(0, ab.cooldown[level-1]);
			this.manacost = ab.manacost[level-1];
			this.possibleTarget = ab.target;
			this.aoe = ab.aoe;
		}
	}
	
	//================================================================================
    // Checkers
    //================================================================================
	
	public inline function checkOnCooldown():Bool
	{
		return _cooldown.value > 0;
	}
	
	public inline function checkValidity(relation:UnitType):Bool
	{
		switch (possibleTarget)
		{
			case AbilityTarget.Enemy:
				return relation == UnitType.Enemy;
			case AbilityTarget.Allied:
				return relation == UnitType.Ally || relation == UnitType.Self;
			case AbilityTarget.Self:
				return relation == UnitType.Self;
			case AbilityTarget.All:
				return true;
			default:
				return false;
		}
	}
	
	//================================================================================
    // Getters
    //================================================================================
	
	function get_cooldown():Int
	{
		return _cooldown.value;
	}
	
	function get_maxCooldown():Int
	{
		return _cooldown.keyValue;
	}
	
}