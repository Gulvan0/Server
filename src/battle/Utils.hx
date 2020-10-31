package battle;
import managers.AbilityManager.RelativeTeam;
import battle.enums.AbilityType;
using Lambda;

/**
 * @author Gulvan
 */
class Utils 
{
	
	public static function getTeamByRelation(t:Team, rel:RelativeTeam) 
	{
		return rel == Allied? t : oppositeTeam(t);
	}

	public static function oppositeTeam(t:Team) 
	{
		return t == Left? Right : Left;
	}
	
	public static function calcBoostedDHP(dhp:Int, caster:Unit, target:Unit):Int
	{
		var boostModifiers:Array<Linear>;
		
		if (dhp > 0)
			boostModifiers = [target.healIn, caster.healOut];
		else
			boostModifiers = [target.damageIn, caster.damageOut];
			
		return Math.round(Linear.combination(boostModifiers).apply(dhp));
		
	}
	
	public static function flipMiss(target:Unit, caster:Unit, ability:Active, ?log:Bool = false):Bool
	{
		var baseMissChance:Float = GameRules.missChance(target.intellect, caster.intellect);
		var hitChance:Float = 1 - baseMissChance;

		if (caster.accuracyMultipliers.has(Math.POSITIVE_INFINITY))
			if (caster.accuracyMultipliers.has(Math.NEGATIVE_INFINITY) || target.evasionMultipliers.has(Math.POSITIVE_INFINITY))
				hitChance = 0.5;
			else
				hitChance = Math.POSITIVE_INFINITY;
		else if (caster.accuracyMultipliers.has(Math.NEGATIVE_INFINITY))
			hitChance = Math.NEGATIVE_INFINITY;
		else
		{
			for (m in caster.accuracyMultipliers)                   //We can only decrease the chances, otherwise, the probability may become >= 1
				if (m <= 1)
					hitChance *= m; 							//Decreasing hit chance
				else 
					hitChance = 1 - ((1 - hitChance) / m);  //Decreasing miss chance

			for (m in target.evasionMultipliers)          
				if (m >= 1)
					hitChance /= m; 							
				else 
					hitChance = 1 - ((1 - hitChance) * m);
			
			if (ability.type == Kick)
				hitChance *= 0.75;
			else if (ability.type != Bolt)
				return false;
		}

		var randValue:Float = Math.random();
		if (log)
			Sys.println('Hit flipping: $randValue < $hitChance?');
		return randValue > hitChance;
	}
	
}