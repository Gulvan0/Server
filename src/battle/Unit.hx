package battle;
import battle.struct.UnitCoords;
import battle.enums.Team;
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

/**
 * Represents unit in battle
 * @author Gulvan
 */
 
class Unit extends Entity
{
	
	public var id(default, null):UnitID;
	public var element(default, null):Element;
	
	public var wheel(default, null):Wheel;
	public var manaPool(default, null):Pool;
	public var alacrityPool(default, null):FloatPool;
	public var buffQueue(default, null):BuffQueue;
	public var delayedPatterns(default, null):DelayedPatternQueue;
	
	private var basicStrength:Int;
	private var basicFlow:Int;
	private var basicIntellect:Int;
	
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
	public var evasionMultipliers(default, null):Array<Float>;
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
		return Math.round(inBonus.apply(_intellect));
	}

	public var speed(get, never):Int;
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

	public function rollCrit(dhp:Int, ?log:Bool = false):Int
	{
		var randValue = Math.random();
		if (log)
			Sys.println('Crit flipping: $randValue < $critChance?');
		if (randValue < critChance)
			return Math.round(critDamage.apply(Math.abs(dhp))) * MathUtils.sign(dhp);
		return dhp;
	}

	public override function asUnit():Unit
	{
		return this;
	}
	
	public function new(id:UnitID, team:Team, position:Int, ?params:Null<ParameterList>) 
	{
		/*if (params == null)
			params = XMLUtils.parseUnit(id);*///TODO: [PvE Update] Rewrite

		super(params.name, new UnitCoords(team, position), params.hp);	

		this.id = id;
		this.element = params.element;
		
		this.wheel = new Wheel(params.wheel, params.abilityLevels, 8);

		this.manaPool = new Pool(params.mana, params.mana);
		this.alacrityPool = new FloatPool(0, 100);
		
		this.basicStrength = params.strength;
		this.basicFlow = params.flow;
		this.basicIntellect = params.intellect;

		this.stBonus = new Linear(1, 0);
		this.flBonus = new Linear(1, 0);
		this.inBonus = new Linear(1, 0);
		this.speedBonus = new Linear(1, 0);
		
		this.buffQueue = new BuffQueue();
		this.delayedPatterns = new DelayedPatternQueue();
		
		this.damageIn = new Linear(1, 0);
		this.damageOut = new Linear(1, 0);
		this.healIn = new Linear(1, 0);
		this.healOut = new Linear(1, 0);
		
		this.critChance = GameRules.baseCritChance;
		this.critDamage = new Linear(GameRules.baseCritMultiplier, 0);

		this.accuracyMultipliers = [];
		this.evasionMultipliers = [];
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
	
}