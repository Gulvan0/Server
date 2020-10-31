package;

import hxassert.Assert;

class Point
{
	public var x:Float;
	public var y:Float;
	
	public function new(x:Float, y:Float)
	{
		this.x = x;
		this.y = y;
	}
}

class Vect
{
	public var dx:Float;
	public var dy:Float;

	public function length() 
	{
		return Math.sqrt(dx*dx + dy*dy);
	}

	public function normalize(?newLength:Int = 1) 
	{
		var coef = newLength/length();
		dx *= coef;
		dy *= coef;
	}
	
	public function new(dx:Float, dy:Float)
	{
		this.dx = dx;
		this.dy = dy;
	}
}

class IntPoint
{
	public var i:Int;
	public var j:Int;
	
	public function new(i:Int, j:Int)
	{
		this.i = i;
		this.j = j;
	}
}

class Rectangle
{
	public var x:Float;
	public var y:Float;
	public var width:Float;
	public var height:Float;
	
	public function new(x:Float, y:Float, width:Float, height:Float)
	{
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
}

/**
 * ...
 * @author Gulvan
 */
class MathUtils 
{

	public static function sign(v:Float):Int
	{
		return (v == 0)? 0 : (v > 0)? 1 : -1;
	}

	public static function iabs(v:Int):Int
	{
		return (v > 0)? v : -v;
	}
	
	public static function inRange(number:Float, leftBorder:Float, rightBorder:Float, ?leftIncluded:Bool = true, ?rightIncluded:Bool = true):Bool 
	{
		if (number >= leftBorder && number <= rightBorder)
			if (leftIncluded || number != leftBorder)
				if (rightIncluded || number != rightBorder)
					return true;
		return false;
	}
	
	public static function randomInt(leftBorder:Int, rightBorder:Int):Int
	{
		return leftBorder + Math.round(Math.random() * (rightBorder - leftBorder));
	}
	
	public static function flip():Bool
	{
		return Math.random() >= 0.5;
	}

	public static function argmax<T>(arr:Array<T>, f:T->Float):{arg:Array<T>, val:Float}
	{
		Assert.assert(!Lambda.empty(arr));
		var max:Float = f(arr[0]);
		var candidates:Array<T> = [arr[0]];
		for (i in 1...arr.length)
		{
			var arg = arr[i];
			var val = f(arg);
			if (val > max)
			{
				max = val;
				candidates = [arg];
			}
			else if (val == max)
				candidates.push(arg);
		}
		return {arg:candidates, val:max};
	}

	public static function argmin<T>(arr:Array<T>, f:T->Float):{arg:Array<T>, val:Float}
	{
		return argmax(arr, (t -> -f(t)));
	}

	public static function sum<T>(arr:Array<T>, f:T->Float):Float
	{
		var s:Float = 0;
		for (el in arr)
			sum += f(el);
		return s;
	}

	public static function rand<T>(arr:Array<T>):T
	{
		return arr[Math.floor(Math.random() * arr.length)];
	}

	public static function removeOn<T>(arr:Array<T>, pred:T->Bool)
	{
		for (el in arr)
			if (pred(el))
			{
				arr.remove(el);
				return;
			}
	}
	
}