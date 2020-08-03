package battle.data;
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
	//TODO: Rewrite switch and implementations
	private static var model:IMutableModel;
	
	private static var target:Unit;
	private static var mode:BuffMode;
	private static var data:EffectData;
	
	public static function useBuff(mod:IMutableModel, id:BuffID, targetCoords:UnitCoords, casterCoords:UnitCoords, m:BuffMode, properties:Map<String, String>, ?procData:EffectData)
	{
		Assert.require(m == BuffMode.Proc || procData == null);

		model = mod;
		target = model.getUnits().get(targetCoords);
		mode = m;
		data = procData;
		
		switch id {
			case LgCharged: charged();
			case LgReEnergizing: reenergizing();
			case LgEnergyBarrier: energyBarrier();
			case LgClarity:
			case LgSnared:
			case LgStrikeback:
			case LgReboot:
			case LgMagnetized:
			case LgManaShiftPos:
			case LgManaShiftNeg:
			case LgLightningShield:
			case LgBlessed:
			case LgDCForm:
			case LgACForm:
		}
	}
	
	private static function charged()
	{
		switch (mode)
		{
			case BuffMode.Cast:
				target.flow = Math.round(target.flow * 1.5);
			case BuffMode.End:
				target.flow = Math.round(target.flow / 1.5);
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
	
	private static function conductivity()
	{
		var modifier:Linear = new Linear(1.5, 0);
		switch (mode)
		{
			case BuffMode.Cast:
				target.healIn.combine(modifier);
				target.damageIn.combine(modifier);
			case BuffMode.End:
				target.healIn.detach(modifier);
				target.damageIn.detach(modifier);
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
	
	private static function strikeback()
	{
		var modifier:Linear = new Linear(2, 0);
		
		switch (mode)
		{
			case BuffMode.Cast:
				target.critDamage.combine(modifier);
			case BuffMode.End:
				target.critDamage.detach(modifier);
			default:
		}
	}
	
	private static function energized()
	{
		var modifier:Linear = new Linear(2, 0);
		
		switch (mode)
		{
			case BuffMode.Cast:
				target.damageOut.combine(modifier);
			case BuffMode.End:
				target.damageOut.detach(modifier);
			default:
		}
	}
	
	private static function snared()
	{
		switch (mode)
		{
			case BuffMode.Cast:
				target.flow = Math.floor(target.flow / 2);
			case BuffMode.End:
				target.flow = target.flow * 2;
			case BuffMode.Proc:
				target.buffQueue.dispellOneByID(LgSnared);
			default:
		}
	}
	
}