package battle.data;
import hxassert.Assert;
import ID.BuffID;
import ID.AbilityID;
import battle.EffectHandler.EffectData;
import battle.Unit;
import battle.enums.Source;
import battle.struct.UnitCoords;

enum BattleEvent 
{
	HPUpdate;
	ManaUpdate;
	AlacUpdate;
	Throw;
	IncomingStrike;
	OutgoingStrike;
	IncomingMiss;
	OutgoingMiss;
	Tick;
	Death;
	OutgoingCrit;
}

/**
 * @author Gulvan
 */

class Passives 
{
	
	private static var model:IMutableModel;
	
	private static var event:BattleEvent;
	private static var data:EffectData;
	
	public static function handle(m:IMutableModel, id:AbilityID, level:Int, e:BattleEvent, dataObj:EffectData) 
	{
		Assert.require(level > 0);
		model = m;
		event = e;
		data = dataObj;
		
		switch (id)
		{
			case LgStrikeback:
				strikeback(level);
			case LgThunderbirdSoul:
				thunderbirdSoul(level);
			case LgEnergyBarrier:
				energyBarrier(level);
			default:
				Assert.fail('Passive $id has no effect handler');
		}
	}
	
	private static function strikeback(level:Int)
	{
		var muls:Array<Float> = [1.3, 1.3, 1.3, 1.3, 1.3, 1.5, 1.75];
		model.castBuff(LgStrikeback, UnitCoords.get(data.target), UnitCoords.nullC(), 1, ["mul" => ""+muls[level-1]]);
	}
	
	private static function thunderbirdSoul(level:Int)
	{
		var coeffs:Array<Float> = [0.1, 0.2, 0.3, 0.4, 0.5];
		var regen:Int = -Math.round(coeffs[level-1] * Math.min(0, data.delta));
		model.changeHP(UnitCoords.get(data.caster), UnitCoords.get(data.caster), regen, Element.Lightning, Source.Buff);
	}

	private static function energyBarrier(level:Int)
	{
		var chances:Array<Float> = [0.1, 0.12, 0.14, 0.16, 0.18];
		if (Math.random() < chances[level-1])
			model.castBuff(LgEnergyBarrier, UnitCoords.get(data.target), UnitCoords.get(data.target), 2);
	}
}