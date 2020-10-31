package battle.data;

import battle.struct.UnitCoords;
import battle.enums.Team;
import ID.AbilityID;

enum AuraMode
{
    Enable;
    OverTime;
    Disable;
}

class Auras 
{
    public static function act(aura:AuraEffect, model:Model, affectedEntity:Entity, mode:AuraMode)
    {
        switch aura.id
        {
            case LgSwiftnessAura:
                swiftnessAura(aura.level, model, aura.owner, affectedEntity.asUnit(), mode);
            case SmnReluctantAura:
                reluctantAura(aura.level, model, affectedEntity, mode);
            case SmnSalvationAura:
                salvationAura(aura.level, model, affectedEntity.asUnit(), mode);
            default:
        }
    }

    //=========================================================================================================

    private static function swiftnessAura(level:Int, model:Model, owner:UnitCoords, affected:Unit, event:AuraEvent)
    {
        var selfMultipliers:Array<Float> = [1.1, 1.2, 1.3, 1.4, 1.5];
        var selfMul:Float = selfMultipliers[level-1];
        var allyMul:Float = 1.2;

        var mul:Float = affected.position == owner.pos? selfMul : allyMul;
        var modifier:Linear = new Linear(mul, 0);
        if (event == Activation)
            u.speedBonus.combine(modifier);
        else if (event == Deactivation)
            u.speedBonus.detach(modifier);
    }

    private static function reluctantAura(level:Int, model:Model, affectedEntity:Entity, event:AuraEvent)
    {
        var damageInc = [1.05, 1.1, 1.15, 1.2][level];
        var chance = 0.5;
        switch event 
        {
            case Activation:
                affectedEntity.shields.addRandom(chance);
            case Deactivation:
                affectedEntity.shields.removeRandom(chance);
                if (!affectedEntity.coords.summon)
                    affectedEntity.asUnit().damageOut.detachBatch("reluctant");
            case OverTime:
                if (!affectedEntity.coords.summon)
                    affectedEntity.asUnit().damageOut.combine(new Linear(damageInc, 0), "reluctant");
            default:
        }
    }

    private static function salvationAura(level:Int, model:Model, affectedUnit:Unit, event:AuraEvent)
    {
        var mod = new Linear(2, 0);
        switch event 
        {
            case Activation:
                affectedUnit.healIn.combine(mod);
            case Deactivation:
                affectedUnit.healIn.detach(mod);
            default:
        }
    }
}