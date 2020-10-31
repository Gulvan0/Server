package battle.struct;

import battle.enums.Team;
import managers.AbilityManager.RelativeTeam;

enum EntityRelation
{
	Enemy;
	Ally(self:Bool);
}

class EntityCoords
{
	public var team:Team;
	public var pos:Int;
    public var summon:Bool;
	
	public static function copy():EntityCoords
	{
		return new EntityCoords(team, pos, summon);
	}
	
	public function equals(coords:EntityCoords):Bool
	{
		return pos == coords.pos && team == coords.team && summon == coords.summon;
	}

	public function nearbyUnit():UnitCoords
	{
		return new UnitCoords(team, pos);
	}

	public function absoulteTeam(rel:RelativeTeam):Team
	{
		return rel == Allied? team : Utils.oppositeTeam(team);
	}

	public function figureRelation(coords:EntityCoords):EntityRelation
	{
		if (team == coords.team)
			if (pos == coords.pos)
				return Ally(true);
			else
				return Ally(false);
		else
			return Enemy;
	}
    
    public function new(team:Team, pos:Int, summon:Bool) 
	{
		Assert.assert(pos.inRange(0, 2));

		this.team = team;
		this.pos = pos;
		this.summon = summon;
	}
}