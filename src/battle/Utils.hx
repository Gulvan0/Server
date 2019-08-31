package battle;
import battle.enums.StrikeType;

/**
 * @author Gulvan
 */
class Utils 
{

	public static function calcCrit(dhp:Int, caster:Unit):Int
	{
		return Math.round(caster.critDamage.apply(dhp));
	}
	
	public static function flipCrit(caster:Unit):Bool
	{
		return Math.random() < caster.critChance.apply(1);
	}
	
	public static function calcBoost(dhp:Int, caster:Unit, target:Unit):Int
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
		var baseChance:Float = 1;
		return switch (ability.strikeType)
		{
			case StrikeType.Bolt: 0.75 * baseChance >= Math.random();
			case StrikeType.Spell: false;
			case StrikeType.Kick: baseChance >= Math.random();
		}
	}
	
}