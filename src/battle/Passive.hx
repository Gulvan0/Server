package battle;
import ID.AbilityID;
import battle.data.Passives.BattleEvent;

/**
 * Passive ability
 * @author Gulvan
 */
class Passive extends Ability 
{
	
	public var triggers(default, null):Array<BattleEvent>;
	
	public function reactsTo(event:BattleEvent):Bool
	{
		for (e in triggers)
			if (e == event)
				return true;
		return false;
	}
	
	public function new(id:AbilityID) 
	{
		super(id);
		//TODO: Rewrite
		//this.triggers = XMLUtils.parseTriggers(id);
	}
	
}