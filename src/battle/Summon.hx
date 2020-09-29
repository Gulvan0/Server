package battle;

import battle.struct.ShieldQueue;
import managers.SummonManager;
import battle.struct.UnitCoords;
import battle.struct.Pool;
import ID.AbilityID;
import battle.enums.Team;
import ID.SummonID;

class Summon 
{
    public var id(default, null):SummonID;
	public var name(default, null):String;
	public var level(default, null):Int;
	public var team(default, null):Team;
    public var position(default, null):Int;

    public var hpPool(default, null):Pool;
    public var shields(default, null):ShieldQueue;
    public var evasionChance(default, null):Linear;

    public function decrementHP() 
    {
        hpPool.value--;
    }

    public function dead():Bool
    {
        return hpPool.value == 0;
    }

    public function new(id:SummonID, coords:UnitCoords, level:Int) 
    {
        this.id = id;
        this.team = coords.team;
        this.position = coords.pos;
        this.level = level;
        
        var parsedObj = SummonManager.summons.get(id);
        this.name = parsedObj.name;
        var maxhp = parsedObj.maxhp[level];
        this.hpPool = new Pool(maxhp, maxhp);
        this.shields = new ShieldQueue();
        this.evasionChance = new Linear(GameRules.summonEvadeChance, 0);
    }
}