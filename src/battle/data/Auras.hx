package battle.data;

import battle.struct.UnitCoords;
import battle.enums.Team;
import ID.AbilityID;

enum AuraEvent
{
    Activation;
    OverTime;
    Deactivation;
    SummonActivation(coords:UnitCoords);
}

class Auras 
{
    public static function activate(aura:Aura, model:Model)
    {
        switch aura.id
        {
            case LgSwiftnessAura:
                swiftnessAura(aura.level, model, aura.owner, Activation);
            case SmnReluctantAura:
                reluctantAuraPassive(aura.level, model, aura.getAffectedTeam(), Activation);
            case SmnSalvationAura:
                salvationAura(aura.level, model, aura.getAffectedTeam(), Activation);
            default:
        }
    }

    public static function overtime(aura:Aura, model:Model, unitToAffect:UnitCoords)
    {
        switch aura.id
        {
            case SmnReluctantAura:
                reluctantAuraOvertime(aura.level, model, unitToAffect);
            default:
        }
    }

    public static function deactivate(aura:Aura, model:Model)
    {
        switch aura.id
        {
            case LgSwiftnessAura:
                swiftnessAura(aura.level, model, aura.owner, Deactivation);
            case SmnReluctantAura:
                reluctantAuraPassive(aura.level, model, aura.getAffectedTeam(), Deactivation);
            case SmnSalvationAura:
                salvationAura(aura.level, model, aura.getAffectedTeam(), Deactivation);
            default:
        }
    }

    /**Use only when the new summon appears under the already active aura**/
    public static function activateForSummon(aura:Aura, model:Model, summonToActivate:UnitCoords)
    {
        switch aura.id
        {
            case SmnReluctantAura:
                reluctantAuraPassive(aura.level, model, aura.getAffectedTeam(), SummonActivation(summonToActivate));
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

    private static function reluctantAuraPassive(level:Int, model:Model, affectedTeam:Team, event:AuraEvent)
    {
        var chance = 0.5;
        switch event 
        {
            case Activation:
                for (u in model.units.getTeam(affectedTeam))
                    u.shields.addRandom(chance);
                for (s in model.summons.getTeam(affectedTeam))
                    s.shields.addRandom(chance);
            case Deactivation:
                for (u in model.units.getTeam(affectedTeam))
                {
                    u.shields.removeRandom(chance);
                    u.damageOut.detachBatch("reluctant");
                }
                for (s in model.summons.getTeam(affectedTeam))
                    s.shields.removeRandom(chance);
            case SummonActivation(coords):
                model.summons.get(coords).shields.addRandom(chance);
            default:
        }
    }

    private static function reluctantAuraOvertime(level:Int, model:Model, affectedUnit:UnitCoords)
    {
        var damageInc = [1.05, 1.1, 1.15, 1.2][level];
        model.units.get(affectedUnit).damageOut.combine(new Linear(damageInc, 0), "reluctant");
    }

    private static function salvationAura(level:Int, model:Model, affectedTeam:Team, event:AuraEvent)
    {
        var mod = new Linear(2, 0);
        switch event 
        {
            case Activation:
                for (u in model.units.getTeam(affectedTeam))
                    u.healIn.combine(mod);
            case Deactivation:
                for (u in model.units.getTeam(affectedTeam))
                    u.healIn.detach(mod);
            default:
        }
    }
}