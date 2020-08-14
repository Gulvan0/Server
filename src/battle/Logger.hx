package battle;

import battle.struct.UPair;
import battle.enums.AbilityType;
import ID.AbilityID;
import battle.struct.UnitCoords;
import battle.enums.Source;

class Logger implements IModelObserver 
{
    private var getUnits:Void->UPair<Unit>;

    public function hpUpdate(target:Unit, caster:Unit, dhp:Int, element:Element, crit:Bool, source:Source):Void 
	{
        var absvalue = Math.abs(dhp);
        var action = dhp > 0? "healing" : "damage";
        var totalAction = crit? '$absvalue critical $action': '$absvalue $action';
        if (source == God)
            Sys.println('${caster.name} recieves $totalAction (GOD)');
        else if (source == Buff)
            Sys.println('${caster.name} deals $totalAction to ${target.name} (BUFF)');
        else 
            Sys.println('${caster.name} deals $totalAction to ${target.name} (ABI)');
        Sys.println('New HP value: ${target.hpPool.value}');
	}
	
	public function manaUpdate(target:Unit, dmana:Int, source:Source):Void 
	{
        var absvalue = Math.abs(dmana);
        var action = dmana > 0? "loses" : "gains";
		if (source == God)
            Sys.println('${target.name} $action $absvalue mana (GOD)');
        else if (source == Buff)
            Sys.println('${target.name} $action $absvalue mana (BUFF)');
        else
            Sys.println('${target.name} $action $absvalue mana (ABI)');
        Sys.println('New MANA value: ${target.manaPool.value}');
	}
	
	public function alacUpdate(unit:Unit, dalac:Float, source:Source):Void 
	{
        var absvalue = Math.abs(dalac);
        var action = dalac > 0? "loses" : "gains";
        if (unit.alacrityPool.value == unit.alacrityPool.minValue && source == God)
            Sys.println('${unit.name}\'s turn');
        else if (source == Buff)
            Sys.println('${unit.name} $action $absvalue alacrity (BUFF)');
        else if (source == Ability)
            Sys.println('${unit.name} $action $absvalue alacrity (ABI)');
	}
	
	public function buffQueueUpdate(unit:UnitCoords, queue:Array<Buff>):Void //TODO: [Improvements] Cast & Dispell events
	{
        var str = '${unit}\'s queue updated: ';
        if (Lambda.empty(queue))
            str += '[Empty]';
        else
        {
            for (b in queue)
                str += '${b.name}, ';
            str = str.substr(0, str.length - 2);
        }
		Sys.println(str);
	}
	
	public function preTick(current:Unit):Void 
	{
		//No action
	}
	
	public function tick(current:Unit):Void 
	{
		Sys.println('${current.name} is being processed');
	}
	
	public function miss(target:UnitCoords, caster:UnitCoords, element:Element):Void 
	{
		Sys.println('Miss!'); //Names are printed in abThrow
	}
	
	public function death(unit:UnitCoords):Void 
	{
        var u = getUnits().get(unit);
		Sys.println('${u.name} dies');
	}
	
	public function abThrown(target:UnitCoords, caster:UnitCoords, id:AbilityID, type:AbilityType, element:Element):Void 
	{
        var c = getUnits().get(caster);
        var t = getUnits().get(target);
		Sys.println('${c.name} uses ${id.getName()} on ${t.name}');
	}
	
	public function abStriked(target:UnitCoords, caster:UnitCoords, ab:Ability, pattern:String):Void 
	{
		Sys.println('Hit!');
    }
    
    public function new(unitRetriever:Void->UPair<Unit>) 
    {
        this.getUnits = unitRetriever;
    }
}