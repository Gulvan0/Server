package;

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
	
	public static inline function inside(point:Point, field:Rectangle):Bool
	{
		if ((point.x >= field.x && point.x <= field.x + field.width) && (point.y >= field.y && point.y <= field.y + field.height))
			return true;
		return false;
	}
	
	public static function distance(point1:Point, point2:Point):Float
	{
		var x1:Float = point1.x;
		var x2:Float = point2.x;
		var y1:Float = point1.y;
		var y2:Float = point2.y;
		
		return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
	}
	
	public static function randomInt(leftBorder:Int, rightBorder:Int):Int
	{
		return leftBorder + Math.round(Math.random() * (rightBorder - leftBorder));
	}
	
	public static function flip():Bool
	{
		return Math.random() >= 0.5;
	}
	
}