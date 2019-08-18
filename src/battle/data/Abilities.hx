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
	
	public static function hit(m:IMutableModel, id:ID, targetCoords:UnitCoords, casterCoords:UnitCoords, e:Element, ?hitNumber:Int)
	{
		model = m;
		target = model.getUnits().get(targetCoords);
		caster = model.getUnits().get(casterCoords);
		element = e;
		
		switch (id)
		{
			//Lg
			case ID.LgShockTherapy: shockTherapy();
			case ID.LgHighVoltage: highVoltage(hitNumber);
			case ID.LgElectricalStorm: electricalStorm(hitNumber);
			case ID.LgCharge: charge();
			case ID.LgLightningBolt: lightningBolt(hitNumber);
			case ID.LgVoltSnare: voltSnare();
			case ID.LgEnergize: energize();
			case ID.LgDisrupt: disrupt();
			case ID.LgArcFlash: arcFlash(hitNumber);
			case ID.LgEMPBlast: empBlast();
			//Other	
			case ID.BoGhostStrike: ghostStrike(hitNumber);
			case ID.StubAbility: stub();
			default:
				throw "Abilities->useAbility() exception: Invalid ID: " + id.getName();
		}
	}

	private static function defaultDistribution(hitNumber:Int, generalHits:Int, generalDamage:Int, ?a:Float = 1.2):Int
	{
		if (hitNumber > generalHits)
			return generalDamage + Math.round((generalDamage + 1)*(1 - Math.pow(a, generalHits - hitNumber))/(generalHits * Math.log(a)));
		else 
			return Math.round(hitNumber * generalDamage / generalHits);
	}
	
	//================================================================================
    // Lg
    //================================================================================
	
	private static function shockTherapy()
	{
		var delta:Int = Math.round(caster.intellect * 3.3);
		if (caster.figureRelation(target) == UnitType.Enemy)
			delta = -delta;
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), delta, element, Source.Ability);
		model.dispellBuffs(UnitCoords.get(target), [Element.Lightning]);
	}
	
	private static function highVoltage(hitNumber:Int = 2)
	{
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -defaultDistribution(hitNumber, 2, caster.intellect * 3), element, Source.Ability);
		if (hitNumber == 1)
			model.castBuff(ID.BuffLgConductivity, UnitCoords.get(target), UnitCoords.get(caster), 2);
	} 
	
	private static function electricalStorm(hitNumber:Int = 2)
	{
		var delta:Int = Math.round(-1.5 * target.buffQueue.elementalCount(Element.Lightning) * caster.intellect);
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), MathUtils.sign(delta) * defaultDistribution(hitNumber, 2, MathUtils.iabs(delta)), element, Source.Ability);
	} 
	
	private static function charge()
	{
		var damage:Int = caster.intellect * 3;
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
		model.castBuff(ID.BuffLgCharged, UnitCoords.get(target), UnitCoords.get(caster), 3);
	}
	
	private static function lightningBolt(hitNumber:Int = 2)
	{
		var damage:Int = Math.round(caster.intellect * 2.5);
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -defaultDistribution(hitNumber, 2, damage), element, Source.Ability);
		if (hitNumber == 1 && Math.random() <= 0.3)
			model.castBuff(ID.BuffLgEnergized, UnitCoords.get(caster), UnitCoords.get(caster), 1);
	}
	
	private static function voltSnare()
	{
		var damage:Int = caster.intellect;
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
		model.castBuff(ID.BuffLgSnared, UnitCoords.get(target), UnitCoords.get(caster), 3);
	}
	
	private static function energize()
	{
		model.castBuff(ID.BuffLgReenergizing, UnitCoords.get(caster), UnitCoords.get(caster), 5);
	}
	
	private static function disrupt()
	{
		var dhp:Int = ((caster.figureRelation(target) == UnitType.Enemy)? -1 : 1) * caster.intellect;
		
		model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), dhp, element, Source.Ability);
		model.dispellBuffs(UnitCoords.get(target));
		model.castBuff(ID.BuffLgClarity, UnitCoords.get(caster), UnitCoords.get(caster), 2);
	}
	
	private static function arcFlash(hitNumber:Int = 2)
	{
		var damage:Int = Math.round(1.5 * caster.intellect);
		var mod:Linear = new Linear(2.5, 0);
		
		if (caster.buffQueue.elementalCount(Element.Lightning) > 0)
		{
			caster.critDamage.combine(mod);
			model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
			caster.critDamage.detach(mod);
		}
		else
			model.changeHP(UnitCoords.get(target), UnitCoords.get(caster), -damage, element, Source.Ability);
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