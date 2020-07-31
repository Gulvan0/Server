package battle.data;

import MathUtils.Vect;
import hxassert.Assert;
import ID.UnitID;

class BotBHMovements 
{
    //? Should receive particle coords as an argument
    public static function attempt(id:UnitID, t:Int):Array<Vect>
    {
        switch (id)
        {
            case Player(l): 
                Assert.fail("Attempting to get preset BH movement of a player");
                return [];
            default: return noise(t);
        }
    }

    //==================================================================================================

    public static function noise(t:Int):Array<Vect>
    {
        var dirAngle:Float = Math.random() * Math.PI * 2;
        return [for (i in 0...5) new Vect(Math.cos(dirAngle), Math.sin(dirAngle))];
    }
}