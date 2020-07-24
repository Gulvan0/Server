package battle.data;
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
	Strike;
	Miss;
	Tick;
	Death;
	Crit;
}

/**
 * ...
 * @author Gulvan
 */

class Passives 
{
	
	private static var model:IMutableModel;
	
	private static var event:BattleEvent;
	private static var data:EffectData;
	
	public static function handle(m:IMutableModel, id:AbilityID, e:BattleEvent, dataObj:EffectData) 
	{
		model = m;
		event = e;
		data = dataObj;
		
		switch (id)
		{
			case AbilityID.LgStrikeback:
				strikeback();
			case AbilityID.LgThunderbirdSoul:
				thunderbirdSoul();
			default:
				throw "Passives->handle() exception: Invalid ID: " + id.getName();
		}
	}
	
	private static function strikeback()
	{
		model.castBuff(LgStrikeback, UnitCoords.get(data.target), UnitCoords.nullC(), 1);
	}
	
	private static function thunderbirdSoul()
	{
		model.changeHP(UnitCoords.get(data.caster), UnitCoords.get(data.caster), -Math.round(data.delta/2), Element.Lightning, Source.Buff);
	}
}