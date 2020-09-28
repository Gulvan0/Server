package battle;

import battle.enums.Team;
import managers.AbilityManager;
import ID.AbilityID;
import battle.struct.UnitCoords;

class Aura 
{
    public var id(default, null):AbilityID;
    public var level(default, null):Int;
    public var owner(default, null):UnitCoords;
    public var summonOwner(default, null):Bool;
    public var affectsAllies(default, null):Bool;
    public var affectsSummons(default, null):Bool;
    public var duration(default, null):Int;

    public function incrDuration()
    {
        duration++;
    }

    public function getAffectedTeam():Team
    {
        return affectsAllies? owner.team : UnitCoords.revertTeam(owner.team);
    }

    public function new(id:AbilityID, level:Int, owner:UnitCoords, summonOwner:Bool) 
    {
        this.id = id;
        this.level = level;
        this.owner = owner;
        this.summonOwner = summonOwner;
        switch (AbilityManager.abilities.get(id).type)
        {
            case Aura(affectsSummons, affectsAllies): 
                this.affectsSummons = affectsSummons;
                this.affectsAllies = affectsAllies;
            default:
        }
        this.duration = 0;
    }
}