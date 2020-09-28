package battle.data;

import ID.AbilityID;
import battle.struct.UnitCoords;
import ID.SummonID;

enum SummonEvent
{
    Summoned;
    OverTime;
}

class SummonActions 
{
    public static function act(model:IMutableModel, summon:SummonID, position:UnitCoords, event:SummonEvent, level:Int)
    {
        switch summon 
        {
            case ReluctantOrb: reluctantOrb(model, position, event, level);
            case SalvationOrb: salvationOrb(model, position, event, level);
        }
    }

    private static function reluctantOrb(model:IMutableModel, position:UnitCoords, event:SummonEvent, level:Int) 
    {
        switch event 
        {
            case Summoned:
                model.applyAura(new Aura(SmnReluctantAura, level, position, true));
            default:
        }
    }

    private static function salvationOrb(model:IMutableModel, position:UnitCoords, event:SummonEvent, level:Int) 
    {
        switch event 
        {
            case Summoned:
                model.applyAura(new Aura(SmnSalvationAura, level, position, true));
            default:
        }
    }
}