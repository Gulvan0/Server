package battle.struct;
import battle.Unit;
import battle.enums.Team;
import hxassert.Assert;

using Lambda;
using MathUtils;

/**
 * @author Gulvan
 */
class UPair<T>
{
	public var left(default, null):Array<T>;
	public var right(default, null):Array<T>;
	public var both(get, never):Array<T>;
	
	///Return an array consisting of elemnts from both arrays (excluding nulls)
	public function get_both():Array<T>
	{
		return left.concat(right).filter(t -> (t != null));
	}
	
	///Return an object bound to unit
	public function get(coords:UnitCoords):T
	{
		var array:Array<T> = (coords.team == Team.Left)? left : right;
		return array[coords.pos];
	}

	public function set(coords:UnitCoords, value:T)
	{
		var array:Array<T> = (coords.team == Team.Left)? left : right;
		array[coords.pos] = value;
	}

	public function nullify(coords:UnitCoords)
	{
		set(coords, null);
	}
	
	///Return an object bound to unit
	public function getByUnit(unit:Unit):T
	{
		var coords:UnitCoords = UnitCoords.get(unit);
		return get(coords);
	}
	
	public function getTeam(team:Team):Array<T>
	{
		return team == Team.Left? left : right;
	}

	public function any(team:Team):T
	{
		var a = getTeam(team).filter(t -> t != null);
		Assert.assert(!Lambda.empty(a));
		return a[0];
	}
	
	///Return an array of unit's enemies (or objects bound to them)
	public function opposite(coords:UnitCoords):Array<T>
	{
		return (coords.team == Team.Left)? right : left;
	}
	
	///Return an array of unit's allies (or objects bound to them) including himself
	public function allied(coords:UnitCoords):Array<T>
	{
		return (coords.team == Team.Left)? left : right;
	}
	
	///Attempt to find the object and return its coords or null if not found
	public function find(obj:T):Null<UnitCoords>
	{
		for (i in 0...left.length)
			if (left[i] == obj)
				return new UnitCoords(Team.Left, i);
		for (i in 0...right.length)
			if (right[i] == obj)
				return new UnitCoords(Team.Right, i);
		return null;
	}
	
	///Return an object bound to player
	public inline function player():T
	{
		return left[0];
	}

	public function pmap<S>(func:T->S):UPair<S>
	{
		return UPair.map(left, right, func);
	}
	
	public static function map<T, S>(left:Array<T>, right:Array<T>, func:T->S):UPair<S>
	{
		return new UPair(Lambda.map(left, func).array(), Lambda.map(right, func).array());
	}
	
	public function new(left:Array<T>, right:Array<T>) 
	{
		Assert.assert(left.length.inRange(1, 3));
		Assert.assert(right.length.inRange(1, 3));
		
		this.left = left;
		this.right = right;
	}
	
	public function iterator():Iterator<T>
	{
		return new UPairIterator(this);
	}
}