package;

/**
 * Represents a linear equation
 * @author Gulvan
 */
class Linear 
{
	
	public var k:Float;
	public var b:Float;
	private var memory:Map<String, Linear> = [];
	
	public static function combination(linears:Array<Linear>):Linear
	{
		var result:Linear = new Linear(1, 0);
		
		for (lin in linears)
		{
			result.k *= lin.k;
			result.b += lin.b;
		}
		
		return result;
	}
	
	public function apply(x:Float):Float
	{
		return k * x + b;
	}
	
	public function combine(lin2:Linear, ?type:String)
	{
		this.k *= lin2.k;
		this.b += lin2.b;
		if (type != null)
		{
			if (!memory.exists(type))
				memory.set(type, new Linear(lin2.k, lin2.b));
			else
				memory.get(type).combine(lin2);
		}
	}

	public function detachBatch(type:String)
	{
		if (memory.exists(type))
		{
			detach(memory.get(type));
			memory.remove(type);
		}
	}
	
	public function detach(lin2:Linear)
	{
		this.k /= lin2.k;
		this.b -= lin2.b;
	}
	
	public function toString():String
	{
		return "" + k + "x + " + b; 
	}
	
	public function new(k:Float, b:Float) 
	{
		this.k = k;
		this.b = b;
	}
	
}