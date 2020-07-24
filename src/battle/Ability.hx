package battle;
import ID.AbilityID;
import battle.enums.AbilityTarget;
import battle.enums.AbilityType;
import Element;

class LightweightAbility
{
	public var id:AbilityID;
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

	public var id(default, null):AbilityID;
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
	
	public function new(id:AbilityID) 
	{
		this.id = id;
		if (!checkEmpty())
		{
			//TODO: Fill
			/*this.name = XMLUtils.parseAbility(id, "name", "");
			this.description = XMLUtils.parseAbility(id, "description", "");
			this.type = XMLUtils.parseAbility(id, "type", AbilityType);
			this.element = XMLUtils.parseAbility(id, "element", Element);*/
		}
	}
	
	public inline function checkEmpty():Bool
	{
		return id == AbilityID.EmptyAbility || id == AbilityID.LockAbility;
	}
	
}