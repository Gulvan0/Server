package battle;
import battle.enums.Team;
import battle.enums.UnitType;
import battle.struct.BuffQueue;
import battle.struct.ShieldQueue;
import battle.struct.FloatPool;
import battle.struct.Pool;
import battle.struct.Wheel;
import battle.struct.DelayedPatternQueue;
import ID.AbilityID;
import ID.UnitID;
import hxassert.Assert;

typedef ParameterList = {
	var name:String;
	var element:Null<Element>;
	var hp:Int;
	var mana:Int;
	var wheel:Array<AbilityID>;
	var abilityLevels:Map<AbilityID, Int>;
	
	var strength:Int;
	var flow:Int;
	var intellect:Int;
}

typedef SubordinaryParameterList = {
	var buffQueue:BuffQueue;
	
	var critChance:Float;
	var critDamage:Linear;
	var damageIn:Linear;
	var damageOut:Linear;
	var healIn:Linear;
	var healOut:Linear;
}

/**
 * Represents unit in battle
 * @author Gulvan
 */
 
class Unit
{
	
	public var id(default, null):UnitID;
	public var name(default, null):String;
	public var element(default, null):Element;
	public var team(default, null):Team;
	public var position(default, null):Int;
	
	public var wheel(default, null):Wheel;
	public var hpPool(default, null):Pool;
	public var manaPool(default, null):Pool;
	public var alacrityPool(default, null):FloatPool;
	public var buffQueue(default, null):BuffQueue;
	public var delayedPatterns(default, null):DelayedPatternQueue;
	public var shields(default, null):ShieldQueue;
	
	private var _strength:Int;
	private var _flow:Int;
	private var _intellect:Int;
	public var speed(get, never):Int;
	
	public var stBonus:Linear;
	public var flBonus:Linear;
	public var inBonus:Linear;
	public var speedBonus:Linear;

	public var damageIn:Linear;
	public var damageOut:Linear;
	public var healIn:Linear;
	public var healOut:Linear;
	public var critChance(default, null):Float;
	public var critDamage:Linear;
	public var accuracyMultipliers(default, null):Array<Float>;

	public var strength(get, never):Int;
	public function get_strength():Int
	{
		return Math.round(stBonus.apply(_strength));
	}

	public var flow(get, never):Int;
	public function get_flow():Int
	{
		return Math.round(flBonus.apply(_flow));
	}

	public var intellect(get, never):Int;
	public function get_intellect():Int
	{
		return Math.round(speedBonus.apply(_intellect));
	}

	public function get_speed():Int
	{
		return Math.round(speedBonus.apply(flow));
	}

	//==========================================================================================================
	
	public function tick()
	{
		wheel.tick();
		buffQueue.tick();
	}

	public function changeCritChance(delta:Float) 
	{
		critChance += delta;
	}
	
	public function isStunned():Bool
	{
		return buffQueue.stunCondition();
	}
	
	public function isAlive():Bool
	{
		return hpPool.value > 0;
	}

	public function rollCrit(dhp:Int):Int
	{
		if (Math.random() < critChance)
			return Math.round(critDamage.apply(Math.abs(dhp))) * MathUtils.sign(dhp);
		return dhp;
	}
	
	public function new(id:UnitID, team:Team, position:Int, ?params:Null<ParameterList>, ?subparams:Null<SubordinaryParameterList>) 
	{
		Assert.assert(position >= 0 && position <= 2);
		
		/*if (params == null)
			params = XMLUtils.parseUnit(id);*///TODO: [PvE Update] Rewrite
		this.id = id;
		this.name = params.name;
		this.element = params.element;
		this.team = team;
		this.position = position;
		
		this.wheel = new Wheel(params.wheel, params.abilityLevels, 8);

		this.hpPool = new Pool(params.hp, params.hp);
		this.manaPool = new Pool(params.mana, params.mana);
		this.alacrityPool = new FloatPool(0, 100);
		
		this._strength = params.strength;
		this._flow = params.flow;
		this._intellect = params.intellect;

		this.stBonus = new Linear(1, 0);
		this.flBonus = new Linear(1, 0);
		this.inBonus = new Linear(1, 0);
		this.speedBonus = new Linear(1, 0);
		
		this.buffQueue = subparams != null? subparams.buffQueue : new BuffQueue();
		this.delayedPatterns = new DelayedPatternQueue();
		this.shields = new ShieldQueue();
		
		this.damageIn = subparams != null? subparams.damageIn : new Linear(1, 0);
		this.damageOut = subparams != null? subparams.damageOut : new Linear(1, 0);
		this.healIn = subparams != null? subparams.healIn : new Linear(1, 0);
		this.healOut = subparams != null? subparams.healOut : new Linear(1, 0);
		
		this.critChance = subparams != null? subparams.critChance : GameRules.basicCritChance;
		this.critDamage = subparams != null? subparams.critDamage : new Linear(GameRules.basicCritMultiplier, 0);

		this.accuracyMultipliers = [];
	}
	
	public function figureRelation(unit:Unit):UnitType
	{
		if (team != unit.team)
			return UnitType.Enemy;
		else if (position == unit.position)
			return UnitType.Self;
		else
			return UnitType.Ally;
	}
	
	public inline function checkManacost(abilityNum:Int):Bool
	{
		return manaPool.value >= wheel.getActive(abilityNum).manacost;
	}
	
	public inline function isPlayer():Bool
	{
		return switch (id)
		{
			case UnitID.Player(v): true;
			default: false;
		};
	}

	public inline function playerLogin():String
	{
		return switch (id)
		{
			case UnitID.Player(v): v;
			default: "ERROR!";
		};
	}
	
	public inline function same(unit:Unit):Bool
	{
		return team == unit.team && position == unit.position;
	}
	
}