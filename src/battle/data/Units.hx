package battle.data;
import ID.UnitID;
import ID.AbilityID;
import battle.Model.Particle;
import battle.Model.Trajectory;
import battle.Model.Pattern;
import MathUtils.Point;
import battle.Unit;
import battle.struct.UPair;
import battle.struct.UnitCoords;
import haxe.Constraints.Function;
import hxassert.Assert;
import battle.enums.Team;

/**
 * Bot AI
 * @author Gulvan
 */
typedef BotDecision = {target:UnitCoords, abilityNum:Int}
 
class Units 
{
	private static var model:IMutableModel;	
	
	//TODO: Rewrite
	/*public static function getPattern(unit:UnitID, ability:AbilityID):Pattern
	{	
		var trajs:Array<Trajectory> = getTrajectories(unit, ability);
		switch (unit)
		{
			case UnitID.Ghost, UnitID.Archghost:
				if (ability == AbilityID.BoGhostStrike)
					return [new Particle(200, 200, trajs[0]), new Particle(300, 200, trajs[0]), new Particle(400, 200, trajs[0]), new Particle(500, 200, trajs[0])];
			default:
				return [];
		}
		return [];
	}

	public static function getTrajectories(unit:UnitID, ability:AbilityID):Array<Trajectory>
	{
		switch (unit)
		{
			case UnitID.Ghost, UnitID.Archghost:
				if (ability == AbilityID.BoGhostStrike)
					return [BH.linear()];
			default:
				return [];
		}
		return [];
	}*/

	public static function decide(m:IMutableModel, id:UnitID):BotDecision
	{
		model = m;
		
		switch (id)
		{
			case UnitID.Ghost, UnitID.Archghost:
				return ghost();
			default:
				null;
		}
		
		throw "battle.data.Units->decide() exception: Invalid unit ID: " + id.getName();	
	}
	
	private static function ghost():BotDecision
	{
		var target:UnitCoords = findWeakestUnit(model.getUnits().left);
		
		return {target: target, abilityNum: 0};
	}
	
	//================================================================================
    // Supply
    //================================================================================
	
	private static function findWeakestUnit(array:Array<Unit>):UnitCoords 
	{
		Assert.assert(array.length > 0);
		
		var result:Unit = array[0];
		
		for (unit in array)
			if (unit.hpPool.value < result.hpPool.value)
				result = unit;
		
		return new UnitCoords(result.team, result.position);
	}
	
}