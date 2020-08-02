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
		
		switch (id)
		{
			case LgConductivity:
				conductivity();
			case LgCharged:
				charged();
			case LgStrikeback:
				strikeback();
			case LgClarity:
				clarity();
			case LgSnared:
				snared();
			case LgEnergized:
				energized();
			case LgReenergizing:
				reenergizing();
			default:
				throw "Buffs->useBuff() exception: Invalid ID: " + id.getName();
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
	
	private static function charged()
	{
		switch (mode)
		{
			case BuffMode.Cast:
				target.flow *= 2;
			case BuffMode.End:
				target.flow = Math.round(target.flow / 2);
			default:
		}
	}
	
	private static function clarity()
	{
		var modifier:Linear = new Linear(1, 0.5);
		
		switch (mode)
		{
			case BuffMode.Cast:
				target.critChance.combine(modifier);
			case BuffMode.End:
				target.critChance.detach(modifier);
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
	
	private static function reenergizing()
	{
		switch (mode)
		{
			case BuffMode.OverTime:
				model.changeMana(UnitCoords.get(target), UnitCoords.get(target), 20, Source.Buff);
			default:
		}
	}
	
}