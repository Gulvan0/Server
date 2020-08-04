package battle.data;

import battle.struct.UnitCoords;
import battle.enums.Team;
import ID.AbilityID;

class Auras 
{
    public static function activate(ab:AbilityID, level:Int, model:Model, owner:UnitCoords)
    {
        switch ab
        {
            case LgSwiftnessAura:
                swiftnessAura(level, model, owner, true);
            default:
        }
    }

    public static function deactivate(ab:AbilityID, level:Int, model:Model, owner:UnitCoords)
    {
        switch ab
        {
            case LgSwiftnessAura:
                swiftnessAura(level, model, owner, false);
            default:
        }
    }

    //=========================================================================================================

    private static function swiftnessAura(level:Int, model:Model, owner:UnitCoords, activation:Bool)
    {
        var selfMultipliers:Array<Float> = [1.1, 1.2, 1.3, 1.4, 1.5];
        var selfMul:Float = selfMultipliers[level-1];
        var allyMul:Float = 1.2;

        for (u in model.units.allied(owner))
        {
            var mul:Float = u.position == owner.pos? selfMul : allyMul;
            var modifier:Linear = new Linear(mul, 0);
            if (activation)
                u.speedBonus.combine(modifier);
            else 
                u.speedBonus.detach(modifier);
        }

    }
}