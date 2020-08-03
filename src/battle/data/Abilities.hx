package battle.data;
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

	public static function hit(m:IMutableModel, id:AbilityID, targetCoords:UnitCoords, casterCoords:UnitCoords, e:Element, ?hitNumber:Int)
	{
		model = m;
		target = model.getUnits().get(targetCoords);
		caster = model.getUnits().get(casterCoords);
		element = e;
		
		switch (id)
		{
			//Lg
			case LgShockTherapy: shockTherapy();
			case LgHighVoltage: highVoltage(hitNumber);
			case LgElectricalStorm: electricalStorm(hitNumber);
			case LgCharge: charge();
			case LgLightningBolt: lightningBolt(hitNumber);
			case LgVoltSnare: voltSnare();
			case LgEnergize: energize();
			case LgDisrupt: disrupt();
			case LgArcFlash: arcFlash(hitNumber);
			case LgEMPBlast: empBlast();
			//Other	
			case BoGhostStrike: ghostStrike(hitNumber);
			case StubAbility: stub();
			default:
				throw "Abilities->useAbility() exception: Invalid ID: " + id.getName();
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
	
	private static function highVoltage(?hitNumber:Int)
	{
		/*var buffOnHit:Int = 1;
		var expectedHits:Int = 2;
		var expectedDamage:Int = Math.round(caster.intellect * 0.35);

		var delta:Int = -calculateParticleDamage(LgHighVoltage, expectedHits, expectedDamage, hitNumber != null? hitNumber : expectedHits);
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), delta, element, Source.Ability);
		if (hitNumber == null || hitNumber == buffOnHit)
			model.castBuff(LgConductivity, UnitCoords.get(target), UnitCoords.get(caster), 2);*/
	} 
	
	private static function electricalStorm(?hitNumber:Int)
	{
		/*var lgBuffCount:Int = target.buffQueue.elementalCount(Element.Lightning);
		var expectedHits:Int = 2;
		var expectedDamage:Int = Math.round(1.5 * lgBuffCount * caster.intellect);

		var delta:Int = -calculateParticleDamage(LgElectricalStorm, expectedHits, expectedDamage, hitNumber != null? hitNumber : expectedHits);
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), delta, element, Source.Ability);*/
	} 
	
	private static function lightningBolt(?hitNumber:Int)
	{
		/*var expectedHits:Int = 2;
		var expectedDamage:Int = Math.round(caster.intellect * 0.5);

		var delta:Int = -calculateParticleDamage(LgLightningBolt, expectedHits, expectedDamage, hitNumber != null? hitNumber : expectedHits);
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), delta, element, Source.Ability);
		if ((hitNumber == null || hitNumber == 1) && Math.random() <= 0.3)
			model.castBuff(LgEnergized, UnitCoords.get(caster), UnitCoords.get(caster), 1);*/
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

	//=========================================NOT BH===========================================================================

	private static function shockTherapy()
	{
		var delta:Int = Math.round(caster.intellect * 3.3);
		if (caster.figureRelation(target) == UnitType.Enemy)
			delta = -delta;
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), delta, element, Source.Ability);
		model.dispellBuffs(UnitCoords.get(target), [Element.Lightning]);
	}

	private static function charge()
	{
		var damage:Int = caster.intellect * 3;
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
		model.castBuff(LgCharged, UnitCoords.get(target), UnitCoords.get(caster), 3);
	}
	
	private static function voltSnare()
	{
		var damage:Int = caster.intellect;
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
		model.castBuff(LgSnared, UnitCoords.get(target), UnitCoords.get(caster), 3);
	}
	
	private static function energize()
	{
		model.castBuff(LgReEnergizing, UnitCoords.get(caster), UnitCoords.get(caster), 5);
	}
	
	private static function disrupt()
	{
		var dhp:Int = ((caster.figureRelation(target) == UnitType.Enemy)? -1 : 1) * caster.intellect;
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), dhp, element, Source.Ability);
		model.dispellBuffs(UnitCoords.get(target));
		model.castBuff(LgClarity, UnitCoords.get(caster), UnitCoords.get(caster), 2);
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
	
	private static function ghostStrike(hitNumber:Int = 1)
	{
		var damage:Int = caster.strength;
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
	}
	
	//================================================================================
    // End
    //================================================================================
	
	private static function stub()
	{
		//No action
	}
	
}