package battle.data;
import hxassert.Assert;
import battle.IMutableModel;
import battle.Model;
import battle.Unit;
import battle.enums.AbilityTarget;
import battle.enums.AbilityType;
import battle.enums.Source;
import Element;
import battle.enums.Team;
import battle.enums.UnitType;
import battle.struct.UPair;
import battle.struct.UnitCoords;
import haxe.Constraints.Function;
import ID.AbilityID;
import ID.BuffID;

/**
 * Use ability by id
 * @author Gulvan
 */

class Abilities 
{
	private static var model:IMutableModel;
	private static var flag:Bool = true;
	
	private static var target:Unit;
	private static var caster:Unit;
	private static var element:Element;
	
	public static function hit(m:IMutableModel, id:AbilityID, level:Int, targetCoords:UnitCoords, casterCoords:UnitCoords, e:Element, ?hitNumber:Int)
	{
		Assert.require(level > 0);
		model = m;
		target = model.getUnits().get(targetCoords);
		caster = model.getUnits().get(casterCoords);
		element = e;

		switch id {
			case LgLightningBolt: lightningBolt(level);
			case LgCharge: charge(level);
			case LgEnergize: energize(level);
			case LgElectricalStorm: electricalStorm(level);
			case LgDisrupt: disrupt(level);
			case LgVoltSnare: voltSnare(level);
			case LgHighVoltage: highVoltage(level);
			case LgArcFlash: arcFlash(level);
			case LgSparkle: sparkle(level);
			case LgAtomicOverload: atomicOverload(level);
			case LgWarp: warp(level);
			case LgShockTherapy: shockTherapy(level);
			case LgBallLightning: ballLightning(level);
			case LgEMPBlast: empBlast(level);
			case LgReboot: reboot(level);
			case LgMagneticField: magneticField(level);
			case LgManaShift: manaShift(level);
			case LgLightningShield: lightningShield(level);
			case LgRapidStrikes: rapidStrikes(level);
			case LgGuardianOfLight: guardianOfLight(level);
			case LgRejuvenate: rejuvenate(level);
			case LgDCForm: dcForm(level);
			case LgACForm: acForm(level);
			case LgDash: Assert.fail('$id is a danmaku skill; thus hit() has no sense');
			case LgEnergyBarrier, LgThunderbirdSoul, LgStrikeback: Assert.fail('$id is passive; thus hit() has no sense');
			case LgSwiftnessAura: Assert.fail('$id is aura; thus hit() has no sense');
			case EmptyAbility, LockAbility: Assert.fail('$id has no implementation');
			case StubAbility: return;
		}
	}

	//TODO: [Alpha 4.0] Make sure it's impossible to use danmaku skill out of BHGame
	private static function defaultDistribution(hitNumber:Int, expectedHits:Int, expectedDamage:Int, id:AbilityID):Int
	{
		/*var totalParticles:Int = XMLUtils.getParticleCount(id);
		var floatDamage:Float;
		if (hitNumber <= expectedHits)
		{
			var xs:Float = hitNumber / expectedHits + 1;
			floatDamage = (4 * expectedDamage * (Math.asin(xs - 2) + Math.PI / 2)) / (Math.PI * xs);
		}
		else
		{
			var xs:Float = -(hitNumber - expectedHits) / (totalParticles - expectedHits);
			var shift:Float = totalParticles * expectedDamage / expectedHits;
			floatDamage = shift - (4 * (shift - expectedDamage) * (Math.asin(xs) + Math.PI / 2)) / (Math.PI * (2 + xs));
		}
		return Math.round(floatDamage);*/
		return 0;
	}

	private static function calculateParticleDamage(id:AbilityID, expectedHits:Int, expectedDamage:Int, hitNumber:Int):Int
	{
		return defaultDistribution(hitNumber, expectedHits, expectedDamage, id) - (hitNumber > 1? defaultDistribution(hitNumber-1, expectedHits, expectedDamage, id) : 0);
	}
	
	//================================================================================
    // Lg
    //================================================================================
	
	private static function lightningBolt(level:Int)
	{
		var damage:Int = Math.round(caster.intellect * 0.9);

		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
	}

	private static function charge(level:Int)
	{
		var tCoords = UnitCoords.get(target);
		var cCoords = UnitCoords.get(caster);
		var damage:Int = Math.round(caster.intellect * 0.63);
		var duration:Array<Int> = [2, 3, 4];

		model.changeHP(tCoords, cCoords, -damage, element, Source.Ability);
		model.castBuff(LgCharged, cCoords, cCoords, duration[level-1]);
	}
	
	private static function energize(level:Int)
	{
		var cCoords = UnitCoords.get(caster);
		var duration:Array<Int> = [2, 4, 6, 8, 10];
		model.castBuff(LgReEnergizing, cCoords, cCoords, duration[level-1]);
	}
	
	private static function electricalStorm(level:Int)
	{
		var damageCoeff:Array<Float> = [0.2, 0.22, 0.24, 0.26, 0.28];
		var damage:Int = Math.round(caster.intellect * damageCoeff[level-1]);

		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
	} 
	
	private static function disrupt(level:Int)
	{
		var tCoords = UnitCoords.get(target);
		var cCoords = UnitCoords.get(caster);

		var absDeltaCoeff:Array<Float> = [0.6, 0.7, 0.8, 0.9, 1];
		var absDelta:Int = Math.round(caster.intellect * absDeltaCoeff[level-1]);
		var delta:Int = caster.figureRelation(target) == Enemy? -absDelta : absDelta;

		model.changeHP(tCoords, cCoords, delta, element, Source.Ability);
		model.dispellBuffs(tCoords);
		model.castBuff(LgClarity, cCoords, cCoords, 1);
	} 

	private static function voltSnare(level:Int)
	{
		var damage:Int = Math.round(1.35 * caster.intellect);
		var duration:Array<Int> = [1, 2, 3];
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
		model.castBuff(LgSnared, UnitCoords.get(target), UnitCoords.get(caster), duration[level-1]);
	}

	private static function highVoltage(level:Int)
	{
		var damage:Int = Math.round(0.45 * caster.intellect);
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
	}

	private static function arcFlash(level:Int)
	{
		var damage:Int = Math.round(0.9 * caster.intellect);
		var modifierCoeff:Array<Float> = [1.5, 1.6, 1.7, 1.8, 1.9, 2];
		var critModifier:Linear = new Linear(modifierCoeff[level-1], 0);
		if (caster.buffQueue.elementalCount(Lightning) > 0)
		{
			caster.critDamage.combine(critModifier);
			model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
			caster.critDamage.detach(critModifier);
		}
		else
			model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
	}

	private static function sparkle(level:Int)
	{
		var damage:Int = Math.round(0.45 * caster.intellect);
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
	}

	private static function atomicOverload(level:Int)
	{
		var damage:Int = Math.round(0.5 * caster.intellect);
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
	}

	private static function warp(level:Int)
	{
		var drainAmount:Float = target.alacrityPool.value;
		var damage:Int = Math.round(0.02 * caster.intellect * drainAmount);
		
		model.changeAlacrity(UnitCoords.get(target), UnitCoords.get(caster), -drainAmount, Source.Ability);
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
	}

	private static function shockTherapy(level:Int)
	{
		var coeffs:Array<Float> = [0.7, 0.75, 0.8, 0.85, 0.9];
		var startCount:Int = target.buffQueue.elementalCount(Lightning);
		model.dispellBuffs(UnitCoords.get(target), [Element.Lightning]);
		var dispelledCount:Int = startCount - target.buffQueue.elementalCount(Lightning);

		var delta:Int;
		if (dispelledCount > 0)
			delta = -Math.round(caster.intellect * coeffs[level-1] * dispelledCount);
		else 
			delta = Math.round(caster.intellect * 1.5);
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), delta, element, Source.Ability);
	}
	
	private static function ballLightning(level:Int)
	{
		var damageCoeff:Array<Float> = [0.4, 0.42, 0.44, 0.46, 0.48];
		var damage:Int = Math.round(caster.intellect * damageCoeff[level-1]);

		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
	} 
	
	private static function empBlast(level:Int)
	{
		var coeffs:Array<Float> = [1.4, 1.5, 1.6];
		var damage:Int = Math.ceil(coeffs[level-1] * caster.intellect);
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
		model.changeAlacrity(UnitCoords.get(target), UnitCoords.get(caster), -target.alacrityPool.value, Source.Ability);
	}

	private static function reboot(level:Int)
	{
		var durations:Array<Int> = [6, 5, 4, 3, 2];
		var duration:Int = durations[level-1];
		var totalRegen:Float = 0.8 * target.hpPool.maxValue;
		var regenPerTurn:Int = Math.round(totalRegen / (duration + 1));

		model.castBuff(LgReboot, UnitCoords.get(target), UnitCoords.get(caster), duration, ["hpregen" => '$regenPerTurn']);
	} 

	private static function magneticField(level:Int)
	{
		var durations:Array<Int> = [1, 2, 3];
		var damage:Int = Math.round(caster.intellect * 0.45);

		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
		model.castBuff(LgMagnetized, UnitCoords.get(target), UnitCoords.get(caster), durations[level-1]);
	}

	private static function manaShift(level:Int)
	{
		var durations:Array<Int> = [8, 6, 4, 2, 2];
		var totalManaAmounts:Array<Int> = [50, 50, 50, 50, 70];
		var totalManaAmount:Int = Math.round(Math.min(totalManaAmounts[level-1], target.manaPool.value));
		var manaPerTurn:Int = Math.round(totalManaAmount / (durations[level-1] + 1));

		model.castBuff(LgManaShiftNeg, UnitCoords.get(target), UnitCoords.get(caster), durations[level-1], ["mana" => '$manaPerTurn']);
		model.castBuff(LgManaShiftPos, UnitCoords.get(caster), UnitCoords.get(caster), durations[level-1], ["mana" => '$manaPerTurn']);
	}

	private static function lightningShield(level:Int)
	{
		var coeffs:Array<Float> = [0.3, 0.4, 0.5];
		var damage:Int = Math.round(coeffs[level-1] * caster.intellect);

		model.castBuff(LgLightningShield, UnitCoords.get(target), UnitCoords.get(caster), 3, ["chanceIn" => '40', "chanceOut" => '30', "dam" => '$damage']);
	}
	
	private static function rapidStrikes(level:Int)
	{
		var saturationLimit:Int = 250;
		var diff:Int = caster.flow - target.flow;
		var ratio:Float;
		if (diff <= 0)
			ratio = 0;
		else if (diff > saturationLimit)
			ratio = 1;
		else 
			ratio = Math.sqrt(diff / saturationLimit);
		var minDamage:Float = 0.22 * caster.intellect;
		var maxDamage:Float = 0.67 * caster.intellect;
		var damage:Int = Math.round(minDamage + ratio * (maxDamage - minDamage));
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
	}

	private static function guardianOfLight(level:Int)
	{
		model.castBuff(LgBlessed, UnitCoords.get(target), UnitCoords.get(caster), 8);
	}

	private static function rejuvenate(level:Int)
	{
		model.changeMana(UnitCoords.get(target), UnitCoords.get(caster), target.manaPool.maxValue, Source.Ability);
	}

	private static function dcForm(level:Int)
	{
		var manaregens:Array<Int> = [0, 7, 14];
		model.castBuff(LgDCForm, UnitCoords.get(target), UnitCoords.get(caster), 6, ['daminc' => '10', 'mregen' => '${manaregens[level-1]}']);
	}

	private static function acForm(level:Int)
	{
		var manapenaltys:Array<Int> = [40, 30, 20];
		model.castBuff(LgACForm, UnitCoords.get(target), UnitCoords.get(caster), 6, ['daminc' => '20', 'mpenalty' => '${manapenaltys[level-1]}']);
	}
	
	//================================================================================
    // Bots
    //================================================================================
	
	
	
}