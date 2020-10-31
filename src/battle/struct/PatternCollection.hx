package battle.struct;

import ID.UnitID;
import ID.AbilityID;

class PatternCollection 
{
    public var patterns:Array<String>;
    public var selectedNum:Int;

    public function selected() 
    {
        return patterns[selectedNum];    
    }

    public function new(ability:AbilityID, unit:UnitID) 
    {
        patterns = [];
        switch unit 
        {
            case Player(id):
                for (i in 0...3)
                    patterns[i] = PlayerdataManager.instance.getPattern(ability, i, id);
            default:
                patterns = [Units.getPattern(unit, ability)];
        }
        selectedNum = 0;
    }    
}