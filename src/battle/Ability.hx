package battle;
import battle.enums.AttackType;
import managers.AbilityManager;
import ID.AbilityID;
import battle.enums.AbilityTarget;
import battle.enums.AbilityType;
import Element;

class LightweightAbility
{
	public var id:AbilityID;
	public var name:String;
	public var type:AbilityType;
	public var element:Element;
	public var level:Int;
	
	public var target:Null<AbilityTarget>;
	public var manacost:Null<Int>;
	public var cooldown:Null<Int>;
	public var delay:Null<Int>;
	
	public function new()
	{
		
	}
}

/**
 * model OF ability IN battle
 * @author Gulvan
 */
class Ability 
{

	public var id(default, null):AbilityID;
	public var name(default, null):String;
	public var type(default, null):AbilityType;
	public var element(default, null):Element;
	public var level(default, null):Int;
	
	public function toLightweight():LightweightAbility
	{
		var la:LightweightAbility = new LightweightAbility();
		la.id = id;
		la.name = name;
		la.type = type;
		la.element = element;
		return la;
	}

	public function isActive():Bool
	{
		return type != AbilityType.Passive;
	}

	public function isBH():Bool
	{
		return danmakuType() != null;
	}

	public function danmakuType():Null<AttackType>
	{
		return AbilityManager.abilities.get(id).danmakuType;
	}
	
	public function new(id:AbilityID, level:Int) 
	{
		this.id = id;
		this.level = level;
		if (!checkEmpty())
		{
			var ab = AbilityManager.abilities.get(id);
			this.name = ab.name;
			this.type = ab.type;
			this.element = ab.element;
		}
	}
	
	public inline function checkEmpty():Bool
	{
		return id == AbilityID.EmptyAbility || id == AbilityID.LockAbility;
	}
	
}