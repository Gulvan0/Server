package battle;
import battle.enums.AbilityType;
using Lambda;

/**
 * @author Gulvan
 */
class Utils 
{
	
	public static function calcBoostedDHP(dhp:Int, caster:Unit, target:Unit):Int
	{
		var boostModifiers:Array<Linear>;
		
		if (dhp > 0)
			boostModifiers = [target.healIn, caster.healOut];
		else
			boostModifiers = [target.damageIn, caster.damageOut];
			
		return Math.round(Linear.combination(boostModifiers).apply(dhp));
		
	}
	
	public static function flipMiss(target:Unit, caster:Unit, ability:Active):Bool
	{
		var baseMissChance:Float = GameRules.baseMissChance + (target.intellect - caster.intellect) * GameRules.missChancePerDeltaIn;
		var baseHitChance:Float = 1 - baseMissChance;

		if (caster.accuracyMultipliers.has(Math.POSITIVE_INFINITY))
			if (caster.accuracyMultipliers.has(Math.NEGATIVE_INFINITY))
				baseHitChance = 0.5;
			else
				baseHitChance = Math.POSITIVE_INFINITY;
		else if (caster.accuracyMultipliers.has(Math.NEGATIVE_INFINITY))
			baseHitChance = Math.NEGATIVE_INFINITY;
		else
			for (m in caster.accuracyMultipliers)
				baseHitChance *= m;

		var missChance:Float = 1 - baseHitChance;
		return switch (ability.type)
		{
			case AbilityType.Bolt: 0.75 * missChance >= Math.random();
			case AbilityType.Spell: false;
			case AbilityType.Kick: missChance >= Math.random();
			default: false;
		}
	}
	
}