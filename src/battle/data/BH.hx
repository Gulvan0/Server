package battle.data;

import MathUtils.Point;

enum BHParameterUnit
{
    Number;
    Degree;
}

typedef BHParameterDetails = {name:String, unit:BHParameterUnit, from:Float, to:Float};

class BH
{

    public static function getParameterDetails(id:ID):Array<BHParameterDetails>
    {
        var result:Array<BHParameterDetails> = [];
        var xml:Xml = XMLUtils.getBHParameters(id);
        for (param in xml.elementsNamed("param"))
        {
            var unit:BHParameterUnit;
            for (u in param.elementsNamed("unit"))
            {
                unit = BHParameterUnit.createByName(u.firstChild().nodeValue);
                break;
            }
            var from:Float;
            for (f in param.elementsNamed("from"))
            {
                from = Std.parseFloat(f.firstChild().nodeValue);
                break;
            }
            var to:Float;
            for (t in param.elementsNamed("to"))
            {
                to = Std.parseFloat(t.firstChild().nodeValue);
                break;
            }
            result.push({name: param.get("name"), unit: unit, from: from, to: to});
        }
        return result;
    }

    public static function convertToTrajectory(id:ID, params:Map<String, Float>):Array<Point>
    {
        return switch (id)
        {
            case ID.LgLightningBolt: accelerate(linear(params["angle"]), 2);
            case ID.LgHighVoltage: accelerate(linear(), 2);
            case ID.LgElectricalStorm: accelerate(linear(), 3);
            case ID.LgArcFlash: accelerate(linear(), 4);
            default: null;
        }
    }

    private static function accelerate(traj:Array<Point>, speed:Float):Array<Point>
    {
        return traj.map((p:Point) -> new Point(speed * p.x, speed * p.y));
    }

    private static function linear(?angle:Float = 0) 
    {
        return [for (t in 1...501) new Point(-Math.cos(angle * Math.PI / 180), Math.sin(angle * Math.PI / 180))];
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