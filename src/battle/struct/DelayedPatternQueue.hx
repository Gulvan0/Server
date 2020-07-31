package battle.struct;

import ID.AbilityID;
import hxassert.Assert;

class DelayedPatternQueue 
{
    public var abilities(default, null):Array<Active>;
    public var patterns(default, null):Array<String>;
    public var durations(default, null):Array<Int>;

    public function add(ab:Active, ptn:String, ?startDuration:Int) 
    {
        if (startDuration == null)
            startDuration = GameRules.defaultDelayedPatternDuration;
        else
            Assert.require(startDuration > 0);

        abilities.push(ab);
        patterns.push(ptn);
        durations.push(startDuration);
    }

    public function tick()
    {
        var i:Int = 0;
        while (i < durations.length)
        {
            durations[i]--;
            if (durations[i] == 0)
            {
                abilities.splice(i, 1);
                patterns.splice(i, 1);
                durations.splice(i, 1);
            }
            else
                i++;
        }
    }

    public function flush()
    {
        abilities = [];
        patterns = [];
        durations = [];
    }

    public function new() 
    {
        flush();
    }
}