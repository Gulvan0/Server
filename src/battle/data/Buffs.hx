package battle.data;
import battle.data.Passives.BattleEvent;
import hxassert.Assert;
import battle.EffectHandler.EffectData;
import ID.BuffID;
import battle.IMutableModel;
import battle.enums.BuffMode;
import Element;
import battle.enums.Source;
import battle.struct.UPair;
import battle.struct.UnitCoords;
import haxe.Constraints.Function;

/**
 * Use buff by id
 * @author Gulvan
 */
 
class Buffs
{
	private static var model:IMutableModel;
	
	private static var target:Unit;
	private static var mode:BuffMode;
	private static var data:EffectData;
	
	public static function useBuff(mod:IMutableModel, id:BuffID, targetCoords:UnitCoords, casterCoords:UnitCoords, m:BuffMode, properties:Map<String, String>, ?procData:EffectData, ?procCause:BattleEvent)
	{
		Assert.require(m == BuffMode.Proc || (procData == null && procCause == null));

		model = mod;
		target = model.getUnits().get(targetCoords);
		mode = m;
		data = procData;
		
		switch id {
			case LgCharged: charged();
			case LgReEnergizing: reenergizing();
			case LgEnergyBarrier: energyBarrier();
			case LgClarity: clarity();
			case LgSnared: snared();
			case LgStrikeback: strikeback(properties);
			case LgReboot: reboot(properties);
			case LgMagnetized: return;
			case LgManaShiftPos: manaShiftPos(properties);
			case LgManaShiftNeg: manaShiftNeg(properties);
			case LgLightningShield: lightningShield(properties, procCause);
			case LgBlessed: blessed();
			case LgDCForm: dcForm(properties);
			case LgACForm: acForm(properties);
		}
	}
	
	private static function charged()
	{
		var modifier:Linear = new Linear(1.5, 0);
		switch (mode)
		{
			case BuffMode.Cast:
				target.flBonus.combine(modifier);
			case BuffMode.End:
				target.flBonus.detach(modifier);
			default:
		}
	}

	private static function reenergizing()
	{
		switch (mode)
		{
			case BuffMode.OverTime:
				model.changeMana(UnitCoords.get(target), UnitCoords.get(target), 5, Source.Buff);
			default:
		}
	}

	private static function energyBarrier()
	{
		switch (mode)
		{
			case BuffMode.Cast:
				target.shields.addImpenetrable();
			case BuffMode.End:
				target.shields.removeImpenetrable();
			default:
		}
	}
	
	private static function clarity()
	{
		switch (mode)
		{
			case BuffMode.Cast:
				target.changeCritChance(0.5);
			case BuffMode.End:
				target.changeCritChance(-0.5);
			default:
		}
	}
	
	private static function snared()
	{
		var modifier:Linear = new Linear(0.2, 0);
		switch (mode)
		{
			case BuffMode.Cast:
				target.speedBonus.combine(modifier);
			case BuffMode.End:
				target.speedBonus.detach(modifier);
			case BuffMode.Proc:
				target.buffQueue.dispellOneByID(LgSnared);
			default:
		}
	}
	
	private static function strikeback(properties:Map<String, String>)
	{
		Assert.require(properties.exists("mul"));
		var mul:Float = Std.parseFloat(properties.get("mul"));

		var modifier:Linear = new Linear(mul, 0);
		switch (mode)
		{
			case BuffMode.Cast:
				target.damageOut.combine(modifier);
			case BuffMode.End:
				target.damageOut.detach(modifier);
			default:
		}
	}
	
	private static function reboot(properties:Map<String, String>)
	{
		Assert.require(properties.exists("hpregen%"));
		var hpregenpercentage:Float = Std.parseFloat(properties.get("hpregen%"));
		var hpRegen:Int = Math.round(hpregenpercentage * target.hpPool.maxValue);
		
		switch (mode)
		{
			case BuffMode.OverTime:
				var ownerCoords = UnitCoords.get(target);
				model.changeHP(ownerCoords, ownerCoords, hpRegen, Element.Lightning, Source.Buff);
			default:
		}
	}

	private static function manaShiftPos(properties:Map<String, String>)
	{
		Assert.require(properties.exists("mana"));
		var mana:Int = Math.round(Std.parseFloat(properties.get("mana")));
		
		switch (mode)
		{
			case BuffMode.OverTime:
				var ownerCoords = UnitCoords.get(target);
				model.changeMana(ownerCoords, ownerCoords, mana, Source.Buff);
			default:
		}
	}

	private static function manaShiftNeg(properties:Map<String, String>)
	{
		Assert.require(properties.exists("mana"));
		var mana:Int = Math.round(Std.parseFloat(properties.get("mana")));
		
		switch (mode)
		{
			case BuffMode.OverTime:
				var ownerCoords = UnitCoords.get(target);
				model.changeMana(ownerCoords, ownerCoords, -mana, Source.Buff);
			default:
		}
	}

	private static function lightningShield(properties:Map<String, String>, cause:BattleEvent)
	{
		Assert.require(properties.exists("chanceIn") && properties.exists("chanceOut") && properties.exists("dam"));
		var chanceIn:Float = Std.parseInt(properties.get("chanceIn")) / 100;
		var chanceOut:Float = Std.parseInt(properties.get("chanceOut")) / 100;
		var damage:Int = Std.parseInt(properties.get("dam"));
		
		switch (mode)
		{
			case BuffMode.Proc:
				if (cause == IncomingStrike && Math.random() < chanceIn)
					model.changeHP(UnitCoords.get(data.caster), UnitCoords.get(target), -damage, Element.Lightning, Source.Buff);
				else if (cause == OutgoingStrike && Math.random() < chanceOut)
					model.changeHP(UnitCoords.get(data.target), UnitCoords.get(target), -damage, Element.Lightning, Source.Buff);
			default:
		}
	}

	private static function blessed()
	{
		var multiplier:Float = Math.POSITIVE_INFINITY;
		switch (mode)
		{
			case BuffMode.Cast:
				target.accuracyMultipliers.push(multiplier);
			case BuffMode.End:
				target.accuracyMultipliers.remove(multiplier);
			default:
		}
	}

	private static function dcForm(properties:Map<String, String>)
	{
		Assert.require(properties.exists("mregen") && properties.exists("daminc"));
		var mregen:Int = Std.parseInt(properties.get("mregen"));
		var daminc:Float = Std.parseInt(properties.get("daminc")) / 100;
		var modifier:Linear = new Linear(daminc, 0);
		
		switch (mode)
		{
			case BuffMode.Cast:
				target.damageOut.combine(modifier);
			case BuffMode.OverTime:
				var ownerCoords = UnitCoords.get(target);
				model.changeMana(ownerCoords, ownerCoords, mregen, Source.Buff);
			case BuffMode.End:
				target.damageOut.detach(modifier);
			default:
		}
	}

	private static function acForm(properties:Map<String, String>)
	{
		Assert.require(properties.exists("mregen") && properties.exists("daminc"));
		var mpenalty:Float = Std.parseInt(properties.get("daminc")) / 100;
		var daminc:Float = Std.parseInt(properties.get("daminc")) / 100;
		var modifier:Linear = new Linear(daminc, 0);
		var absolutePenalty:Int = Math.round(mpenalty*target.manaPool.maxValue);
		
		switch (mode)
		{
			case BuffMode.Cast:
				var ownerCoords = UnitCoords.get(target);
				model.changeMana(ownerCoords, ownerCoords, -absolutePenalty, Source.Buff);
				target.damageOut.combine(modifier);
			case BuffMode.End:
				target.damageOut.detach(modifier);
			default:
		}
	}
	
}