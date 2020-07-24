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
	
	public function new(id:AbilityID, level:Int) 
	{
		super(id, level);
		//TODO: Rewrite (needs analysis on where to store info about triggers)
		//this.triggers = XMLUtils.parseTriggers(id);
	}
	
}