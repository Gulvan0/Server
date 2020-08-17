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

enum BuffQueueState
{
	OwnersTurn;
	OthersTurn;
}

/**
 * Represents a unit's queue of buffs
 * @author Gulvan
 */
class BuffQueue
{

	public var queue(get, never):Array<Buff>;
	private var activated:Array<Buff>;
	private var notActivated:Array<Buff>;
	public var state(default, set):BuffQueueState;
	
	public function get_queue():Array<Buff>
	{
		return activated.concat(notActivated);
	}

	public function set_state(v:BuffQueueState):BuffQueueState
	{
		if (state == OwnersTurn && v == OthersTurn)
		{
			activated = activated.concat(notActivated);
			notActivated = [];
		}
		return state = v;
	}

	public function addBuff(buff:Buff)
	{
		var index:Int = indexOfBuff(buff.id);
		
		if (index == -1 || buff.flags.has(Stackable))
		{
			if (state == OwnersTurn)
				notActivated.push(buff);
			else 
				activated.push(buff);
			buff.onCast();
		}
		else
			queue[index] = buff;
	}
	
	public function tick()
	{
		var i:Int = 0;
		while (i < activated.length)
		{
			if (activated[i].tickAndCheckEnded())
				dispellBuff(i);
			else
				i++;
		}
		for (buff in notActivated)
			buff.overtimeWithoutTick();
	}
	
	public function getTriggering(e:BattleEvent):Array<Buff>
	{
		return activated.filter(b -> b.reactsTo(e));
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
	public function dispellByElement(?elements:Array<Element>, ?count:Null<Int>):Bool
	{
		Assert.assert(count == null || count > 0);
		
		var startCount:Int = queue.length;
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

		return startCount != queue.length;
	}
	
	private function dispellBuff(index:Int)
	{
		if (index < 0 || index >= activated.length + notActivated.length)
			return;

		if (index < activated.length)
		{
			if (activated[index].undispellable())
				return;
			activated[index].onEnd();
			activated.splice(index, 1);
		}
		else 
		{
			var mergedIndex:Int = index - activated.length;
			if (notActivated[mergedIndex].undispellable())
				return;
			notActivated[mergedIndex].onEnd();
			notActivated.splice(mergedIndex, 1);
		}
	}
	
	public function elementalCount(element:Element, ?onlyDispellable:Bool = false):Int
	{
		var count:Int = 0;
		
		for (buff in queue)
			if (buff.element == element)
				if (!onlyDispellable || !buff.undispellable())
					count++;
				
		return count;
	}
	
	public function new() 
	{
		activated = [];
		notActivated = [];
		state = OthersTurn;
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