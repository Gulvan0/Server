package battle;
import battle.enums.AbilityTarget;
import battle.enums.AbilityType;
import Element;

class LightweightAbility
{
	public var id:ID;
	public var name:String;
	public var description:String;
	public var type:AbilityType;
	public var element:Element;
	
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

	public var id(default, null):ID;
	public var name(default, null):String;
	public var description(default, null):String;
	public var type(default, null):AbilityType;
	public var element(default, null):Element;
	
	public function toLightweight():LightweightAbility
	{
		var la:LightweightAbility = new LightweightAbility();
		la.id = id;
		la.name = name;
		la.description = description;
		la.type = type;
		la.element = element;
		return la;
	}
	
	public function new(id:ID) 
	{
		this.id = id;
		if (!checkEmpty() && id != ID.NullID)
		{
			this.name = XMLUtils.parseAbility(id, "name", "");
			this.description = XMLUtils.parseAbility(id, "description", "");
			this.type = XMLUtils.parseAbility(id, "type", AbilityType);
			this.element = XMLUtils.parseAbility(id, "element", Element);
		}
	}
	
	public inline function checkEmpty():Bool
	{
		return id == ID.EmptyAbility || id == ID.LockAbility;
	}
	
}