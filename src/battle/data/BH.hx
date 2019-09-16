package battle.data;

import MathUtils.Point;

enum BHParameterType
{
    Number;
    Angle;
}

typedef BHParameterDetails = {name:String, type:BHParameterType, from:Float, to:Float};

class BH
{

    public static function getParameterDetails(id:ID):Array<BHParameterDetails>
    {
        //from XML
        return null;
    }

    public static function builtInParameters(id:ID):Map<String, Float>
    {
        //from XML
        return null;
    }

    public static function convertToTrajectory(id:ID, params:Map<String, Float>):Array<Point>
    {
        return switch (id)
        {
            case ID.LgLightningBolt: accelerate(linear(params["angle"]), params["speed"]);
            default: null;
        }
    }

    private static function accelerate(traj:Array<Point>, speed:Float):Array<Point>
    {
        return traj.map(function (p:Point) {return new Point(speed * p.x, speed * p.y);});
    }

    private static function linear(angle:Float) 
    {
        return [for (t in 1...501) new Point(Math.cos(angle), Math.sin(angle))];
    }

    private static function polynominal(coefficients:Array<Float>):Array<Point> 
    {
        var traj:Array<Point> = [];
        for (t in 1...501)
        {
            traj[t] = new Point(t, 0);
            for (i in 0...coefficients.length)
                traj[t].y += Math.pow(t, i + 1) * coefficients[i];
        }
        return traj;    
    }
}