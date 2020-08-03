package battle.struct;
import managers.BuffManager.BuffFlag;
import ID.BuffID;
import battle.Buff;
import battle.Model;
import battle.data.Passives.BattleEvent;
import hxassert.Assert;
import Element;
import MathUtils;
using Lambda;

/**
 * Represents a unit's queue of buffs
 * @author Gulvan
 */
class BuffQueue
{

	public var queue(default, null):Array<Buff>;
	private var newBuffs:Int;
	
	public function addBuff(buff:Buff)
	{
		var index:Int = indexOfBuff(buff.id);
		
		if (index == -1 || buff.flags.has(Stackable))
		{
			queue.push(buff);
			buff.onCast();
			newBuffs++;
		}
		else
			queue[index] = buff;
	}
	
	public function tick()
	{
		var i:Int = 0;
		while (i < queue.length)
		{
			if (queue[i].tickAndCheckEnded())
				dispellBuff(i);
			else
				i++;
		}
		newBuffs = 0;
	}
	
	public function getTriggering(e:BattleEvent):Array<Buff>
	{
		var activatedBuffs = queue.slice(0, queue.length - newBuffs);
		return activatedBuffs.filter(b -> b.reactsTo(e));
	}
	
	public function dispellOneByID(id:BuffID)
	{
		var ind:Int = indexOfBuff(id);
		if (ind >= 0)
			dispellBuff(ind);
	}

	public function dispellAllByID(id:BuffID)
	{
		var ind:Int = indexOfBuff(id);
		while (ind >= 0)
		{
			dispellBuff(ind);
			ind = indexOfBuff(id);
		}
	}

	public function stunCondition():Bool 
	{
		for (buff in queue)
			if (buff.flags.has(Stun))
				return true;
		return false;
	}

	/**
	 * If elements == null, buffs are dispelled irrespective of their elements
	 * If count == null, every matching buff is dispelled
	**/
	public function dispellByElement(?elements:Array<Element>, ?count:Null<Int>)
	{
		Assert.assert(count == null || count > 0);
		
		var candidates:Array<Buff> = new Array<Buff>();
		
		if (elements == null)
			candidates = queue;
		else
			candidates = queue.filter(b -> elements.has(b.element));
		
		if (count == null)
			count = candidates.length;
				
		if (count < candidates.length)
			for (i in 0...count)
			{
				var localInd = MathUtils.randomInt(0, candidates.length);
				var globalInd = indexOfBuff(candidates[localInd].id);
				dispellBuff(globalInd);
				candidates.splice(localInd, 1);
			}
		else
			for (buff in candidates)
				dispellBuff(indexOfBuff(buff.id));
	}
	
	private function dispellBuff(index:Int)
	{
		if (index >= 0)
		{
			queue[index].onEnd();
			queue.splice(index, 1);
		}
	}
	
	public function elementalCount(element:Element):Int
	{
		var count:Int = 0;
		
		for (buff in queue)
			if (buff.element == element)
				count++;
				
		return count;
	}
	
	public function new() 
	{
		queue = new Array<battle.Buff>();
		newBuffs = 0;
	}
	
	//We need separate function because we compare only by id. indexOf() thinks that buffs with different current durations are different 
	private function indexOfBuff(id:BuffID):Int
	{
		for (i in 0...queue.length)
			if (queue[i].id == id)
				return i;
				
		return -1;
	}
}