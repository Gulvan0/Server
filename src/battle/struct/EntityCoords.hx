package battle.struct;

class EntityCoords extends UnitCoords 
{
    public var summon:Bool;

    //TODO: getByEntity
    
    public function new(team:Team, pos:Int, summon:Bool) 
	{
		super(team, pos);
		
		this.summon = summon;
	}
}