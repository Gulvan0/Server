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
	
	//TODO: Rewrite the entire class

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
			case LgHighVoltage:
			case LgArcFlash:
			case LgThunderbirdSoul:
			case LgSparkle:
			case LgAtomicOverload:
			case LgStrikeback:
			case LgWarp:
			case LgShockTherapy:
			case LgBallLightning:
			case LgDash:
			case LgEMPBlast:
			case LgReboot:
			case LgSwiftnessAura:
			case LgMagneticField:
			case LgManaShift:
			case LgLightningShield:
			case LgRapidStrikes:
			case LgGuardianOfLight:
			case LgRejuvenate:
			case LgDCForm:
			case LgACForm:
			case LgEnergyBarrier: Assert.fail('$id is passive; thus hit() has no sense');
			case EmptyAbility, LockAbility: Assert.fail('$id has no implementation');
			case StubAbility: return;
		}
	}

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

	private static function arcFlash(?hitNumber:Int)
	{
		/*var expectedHits:Int = 2;
		var particleDamage:Int = Math.round(0.5 * caster.intellect / expectedHits);

		var delta:Int = hitNumber == null? expectedHits * -particleDamage : -particleDamage;
		var mod:Linear = new Linear(2, 0);
		if (caster.buffQueue.elementalCount(Element.Lightning) > 0)
		{
			caster.critDamage.combine(mod);
			model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), delta, element, Source.Ability);
			caster.critDamage.detach(mod);
		}
		else
			model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), delta, element, Source.Ability);*/
	}

	private static function shockTherapy()
	{
		var delta:Int = Math.round(caster.intellect * 3.3);
		if (caster.figureRelation(target) == UnitType.Enemy)
			delta = -delta;
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), delta, element, Source.Ability);
		model.dispellBuffs(UnitCoords.get(target), [Element.Lightning]);
	}
	
	private static function empBlast()
	{
		var damage:Int = Math.ceil(3.5 * caster.intellect);
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
		model.changeAlacrity(UnitCoords.get(target), UnitCoords.get(caster), -target.alacrityPool.value, Source.Ability);
	}
	
	//================================================================================
    // Bots
    //================================================================================
	
	
	
}