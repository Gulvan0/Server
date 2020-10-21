package battle;

import battle.struct.EntityCoords;
import battle.enums.Team;
import managers.AbilityManager;
import ID.AbilityID;
import battle.struct.UnitCoords;

class AuraEffect
{
    public var id(default, null):AbilityID;
    public var level(default, null):Int;
    public var owner(default, null):EntityCoords;
    public var duration(default, null):Int;
    public var evolvingValues(default, null):Map<String, Float>;

    public function incrDuration()
    {
        duration++;
    }

    public function new(id:AbilityID, level:Int, owner:EntityCoords) 
    {
        this.id = id;
        this.level = level;
        this.owner = owner;
        this.duration = 0;
        this.evolvingValues = [];
    }
}