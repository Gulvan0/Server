package battle;

import battle.struct.EntityCoords;
import battle.struct.ShieldQueue;
import managers.SummonManager;
import battle.struct.UnitCoords;
import battle.struct.Pool;
import ID.AbilityID;
import battle.enums.Team;
import ID.SummonID;

class Summon extends Entity
{
    public var id(default, null):SummonID;
	public var level(default, null):Int;

    public override function asSummon():Summon
	{
		return this;
	}

    public function new(id:SummonID, coords:EntityCoords, level:Int) 
    {
        this.id = id;
        this.level = level;

        var parsedObj = SummonManager.summons.get(id);
        super(parsedObj.name, new EntityCoords(coods.team, coords.pos, true), parsedObj.maxhp[level]);
    }
}