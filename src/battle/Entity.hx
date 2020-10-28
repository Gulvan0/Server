package battle;
import battle.struct.UnitCoords;
import battle.struct.EntityCoords;
import battle.enums.Team;
import battle.struct.BuffQueue;
import battle.struct.ShieldQueue;
import battle.struct.FloatPool;
import battle.struct.Pool;
import battle.struct.Wheel;
import battle.struct.DelayedPatternQueue;
import ID.AbilityID;
import ID.UnitID;
import hxassert.Assert;

/**
 * Represents unit or summon in battle
 * @author Gulvan
 */
 
class Entity
{
	public var name(default, null):String;
	public var coords(default, null):EntityCoords;
	
	public var hpPool(default, null):Pool;
	public var shields(default, null):ShieldQueue;
	
	public function isAlive():Bool
	{
		return hpPool.value > 0;
	}

	public function asUnit():Unit
	{
		throw "Illegal cast";
	}

	public function asSummon():Summon
	{
		throw "Illegal cast";
	}
	
	public function new(name:String, coords:EntityCoords, health:Int) 
	{
		this.name = name;
		this.coords = coords;

		this.hpPool = new Pool(health, health);
		this.shields = new ShieldQueue();
	}
	
	public function figureRelation(entity:Entity):EntityRelation
	{
		return coords.figureRelation(entity.coords);
	}
	
	public inline function same(entity:Entity):Bool
	{
		return coords.equals(entity.coords);
	}
	
}