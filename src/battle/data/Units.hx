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

//TODO: [PvE Update] Implement getPattern() and decide()
class Units 
{
	private static var model:IMutableModel;	
	
	public static function getPattern(unit:UnitID, ability:AbilityID):String
	{	
		switch (unit)
		{
			default:
				return "";
		}
	}

	public static function decide(m:IMutableModel, id:UnitID):BotDecision
	{
		model = m;
		
		switch (id)
		{
			default:
				null;
		}
		
		throw "battle.data.Units->decide() exception: Invalid unit ID: " + id.getName();	
	}
	
	private static function straight():BotDecision
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