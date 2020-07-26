package battle;
import managers.AbilityManager;
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
		return Lambda.has(triggers, event);
	}
	
	public function new(id:AbilityID, level:Int) 
	{
		super(id, level);
		if (!checkEmpty())
			this.triggers = AbilityManager.abilities.get(id).triggers;
	}
	
}