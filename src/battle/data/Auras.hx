package battle.data;

import battle.struct.UnitCoords;
import battle.enums.Team;
import ID.AbilityID;

enum AuraEvent
{
    Activation;
    OverTime;
    Deactivation;
}

class Auras 
{
    public static function activate(aura:Aura, model:Model)
    {
        switch aura.id
        {
            case LgSwiftnessAura:
                swiftnessAura(aura.level, model, aura.owner, Activation);
            default:
        }
    }

    public static function overtime(aura:Aura, model:Model, unitToAffect:UnitCoords)
    {
        switch aura.id
        {
            default:
        }
    }

    public static function deactivate(aura:Aura, model:Model)
    {
        switch aura.id
        {
            case LgSwiftnessAura:
                swiftnessAura(aura.level, model, aura.owner, Deactivation);
            default:
        }
    }

    /**Use only when the new summon appears under the already active aura**/
    public static function activateForSummon(aura:Aura, model:Model, summonToActivate:UnitCoords)
    {
        switch aura.id
        {
            default:
        }
    }

    //=========================================================================================================

    private static function swiftnessAura(level:Int, model:Model, owner:UnitCoords, event:AuraEvent)
    {
        var selfMultipliers:Array<Float> = [1.1, 1.2, 1.3, 1.4, 1.5];
        var selfMul:Float = selfMultipliers[level-1];
        var allyMul:Float = 1.2;

        for (u in model.units.allied(owner))
        {
            var mul:Float = u.position == owner.pos? selfMul : allyMul;
            var modifier:Linear = new Linear(mul, 0);
            if (event == Activation)
                u.speedBonus.combine(modifier);
            else if (event == Deactivation)
                u.speedBonus.detach(modifier);
        }

    }
}