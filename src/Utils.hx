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
	
}