package battle.struct;

class ShieldQueue 
{
    public var damageBlock(default, null):Int = 0;
    public var impenetrableCount(default, null):Int = 0;
    public var randomChances(default, null):Array<Float> = [];

    public function add(shieldBlock:Int) 
    {
        damageBlock += shieldBlock;
    }

    public function remove(shieldBlock:Int) 
    {
        damageBlock -= shieldBlock;
    }

    public function addImpenetrable() 
    {
        impenetrableCount++;
    }

    public function removeImpenetrable() 
    {
        impenetrableCount--;
    }

    public function addRandom(chance:Float) 
    {
        randomChances.push(chance);
    }

    public function removeRandom(chance:Float) 
    {
        randomChances.remove(chance);
    }

    public function penetrate(damage:Int):Int
    {
        if (impenetrableCount > 0)
            return 0;
        else if (rollRandoms())
            return 0;
        else if (damage > damageBlock)
        {
            var blocked:Int = damageBlock;
            damageBlock = 0;
            return damage - blocked;
        }
        else 
        {
            damageBlock -= damage;
            return 0;
        }
    }

    private function rollRandoms():Bool
    {
        for (chance in randomChances)
            if (Math.random() < chance)
                return true;
        return false;
    }

    public function new() 
    {
        
    }
}