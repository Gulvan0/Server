package battle.struct;
import hxassert.Assert;
import MathUtils;
import battle.enums.Team;

using MathUtils;

/**
 * Unit coordinates
 * @author Gulvan
 */
class UnitCoords extends EntityCoords
{	

	//Deprecated
	public function get(unit:Unit)
	{
		return unit.coords;
	}
	
	public function new(team:Team, pos:Int) 
	{
		super(team, pos, false);
	}
	
}