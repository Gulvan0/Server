package battle;
import battle.struct.EntityCoords;
import battle.struct.EntityCoords.EntityRelation;
import io.AbilityParser.AbilityFlag;
import ID.AbilityID;
import battle.enums.AbilityTarget;
import managers.AbilityManager;

import battle.struct.Countdown;

/**
 * Active ability
 * @author Gulvan
 */
class Active
{	
	public var id:AbilityID;
	public var level:Int;
	private var _cooldown:Countdown;
	public var cooldown(get, null):Int;
	public var maxCooldown(get, null):Int;
	public var manacost(default, null):Int;
	public var possibleTarget(default, null):AbilityTarget;
	
	public function putOnCooldown()
	{
		_cooldown.value = _cooldown.keyValue;
	}
	
	public function tick()
	{
		if (checkOnCooldown())
			_cooldown.value--;
	}
	
	public inline function checkOnCooldown():Bool
	{
		return _cooldown.value > 0;
	}
	
	public function new(id:AbilityID, level:Int) 
	{
		this.id = id;
		this.level = level;
		
		if (!checkEmpty())
		{
			var ab = AbilityManager.actives.get(id);
			this._cooldown = new Countdown(0, ab.cooldown[level-1]);
			this.manacost = ab.manacost[level-1];
			this.possibleTarget = ab.target;
		}
	}

	public function validForUnit(relation:EntityRelation):Bool
	{
		var validTargets:Array<AbilityTarget> = switch relation 
		{
			case Enemy: [All, Enemy];
			case Ally(self): self? [All, Allied, Self] : [All, Allied];
		}
		return Lambda.has(validTargets, possibleTarget);
	}

	public function validForSummon():Bool
	{
		return possibleTarget == All || possibleTarget == Enemy;
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