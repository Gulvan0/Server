package;

/**
 * ...
 * @author gulvan
 */
class Utils 
{

	public static function find<T>(a:Array<T>, item:T):Null<Int>
	{
		for (i in 0...a.length)
			if (a[i] == item)
				return i;
		return null;
	}

	public static function sumMaps<T>(map:Map<T, Int>, addend:Map<T, Int>):Map<T, Int>
	{
		for (k in map.keys())
			map[k] += addend[k];
		return map;
	}
	
}