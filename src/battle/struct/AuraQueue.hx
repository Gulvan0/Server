package battle.struct;

import battle.data.Auras.AuraMode;

class AuraQueue 
{
    public var queue(default, null):Array<AuraEffect>;
    
    public function add(effect:AuraEffect, model:Model, affected:Entity) 
    {
        queue.push(effect);
		Auras.act(effect, model, affected, Enable);
    }

    public function remove(owner:EntityCoords, model:Model, affected:Entity) 
    {
        for (i in 0...queue.length)
            if (queue[i].owner.equals(owner))
            {
                Auras.act(queue[i], model, affected, Disable);
                queue.splice(i, 1);
            }
    }
    
    public function new() 
    {
        queue = [];
    }
}