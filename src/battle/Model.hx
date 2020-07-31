package battle;
import battle.struct.DelayedPatternQueue;
import battle.enums.AttackType;
import managers.PlayerdataManager;
import ID.AbilityID;
import ID.UnitID;
import ID.BuffID;
import managers.ConnectionManager;
import MathUtils.IntPoint;
import MathUtils.Point;

import Element;
import battle.Ability;
import battle.IInteractiveModel;
import battle.data.Abilities;
import battle.data.Units;
import battle.enums.AbilityType;
import battle.enums.Source;
import battle.enums.Team;
import battle.struct.FloatPool;
import battle.struct.Pool;
import battle.struct.UPair;
import battle.struct.UnitCoords;
import json2object.JsonWriter;
using Lambda;

enum ChooseResult 
{
	Ok;
	Empty;
	Manacost;
	Cooldown;
	Passive;
}

enum TargetResult 
{
	Ok;
	Invalid;
	Nonexistent;
	Dead;
} 

typedef UnitData = {
	var id:UnitID;
	var name:String;
	var element:Element;
	var team:Team;
	var pos:Int;
	var hp:Pool;
	var mana:Pool;
	var alacrity:FloatPool;
	var buffs:Array<Buff.LightweightBuff>;
};

typedef BattleData = {
	var common:Array<UnitData>;
	var personal:Array<LightweightAbility>;
} 

typedef BHInfo = {
	var ability:AbilityID;
	var caster:UnitCoords;
	var element:Element;
};

typedef Trajectory = Array<Point>;
class Particle
{
	public var x:Float;
	public var y:Float;
	public var traj:Trajectory;

	public function new(x:Float, y:Float, traj:Trajectory)
	{
		this.x = x;
		this.y = y;
		this.traj = traj;
	}
}
typedef Pattern = Array<Particle>;

/**
 * @author Gulvan
 */
class Model implements IInteractiveModel implements IMutableModel
{
	
	private var observers:Array<IModelObserver>;
	private var room:BattleRoom;

	public var units(default, null):UPair<Unit>;
	public var currentUnit:UnitCoords;
	
	private var readyUnits:Array<Unit>;

	private var abilityTargets:Array<UnitCoords> = [];
	private var bhInfo:Null<BHInfo> = null;
	private var bhHitsTaken:Map<UnitCoords, Int> = [];

	private var patterns:UPair<Map<AbilityID, Array<String>>>;
	private var selectedPatterns:UPair<Map<AbilityID, Int>>;

	private var onTerminate:(winners:Array<String>, losers:Array<String>, ?draw:Bool)->Void;

	public function getUnits():UPair<Unit>
	{
		return units;
	}
	
	public function getBattleData(login:String):String
	{
		var writer = new JsonWriter<BattleData>();
		return writer.write({common: [for (u in units) {
		id: u.id,
		name: u.name,
		element: u.element,
		team: u.team,
		pos: u.position,
		hp: u.hpPool,
		mana: u.manaPool,
		alacrity: u.alacrityPool,
		buffs: [for (b in u.buffQueue.queue) b.toLightweight()]
		}], personal: units.get(getUnit(login)).wheel.getlwArray()});
	}
	
	private function getUnit(login:String):UnitCoords
	{
		for (u in units)
			switch (u.id) 
			{
				case UnitID.Player(l): 
					if (l == login)
						return UnitCoords.get(u);
				default:
			}
		return UnitCoords.nullC();
	}
	
	private function checkTurn(login:String):Bool
	{
		return getUnit(login).equals(currentUnit);
	}
	
    //================================================================================
    // Mutable
    //================================================================================	
	
	public function changeHP(targetCoords:UnitCoords, casterCoords:UnitCoords, dhp:Int, element:Element, source:Source)
	{
		var target:Unit = units.get(targetCoords);
		var caster:Unit = units.get(casterCoords);
		var crit:Bool = false;
		
		if (source != Source.God)
		{	
			dhp = Utils.calcBoost(dhp, caster, target);
			
			if (Utils.flipCrit(caster))
			{
				crit = true;
				dhp = Utils.calcCrit(dhp, caster);
			}
		}

		target.hpPool.value += dhp;	
		for (o in observers) o.hpUpdate(target, caster, dhp, element, crit, source);
		if (!target.isAlive())
			for (o in observers) o.death(targetCoords);
	}
	
	public function changeMana(targetCoords:UnitCoords, casterCoords:UnitCoords, dmana:Int, source:Source)
	{
		var target:Unit = units.get(targetCoords);
		var caster:Unit = units.get(casterCoords);
		
		target.manaPool.value += dmana;
		
		for (o in observers) o.manaUpdate(target, dmana, source);
	}
	
	public function changeAlacrity(targetCoords:UnitCoords, casterCoords:UnitCoords, dalac:Float, source:Source)
	{
		var target:Unit = units.get(targetCoords);
		var caster:Unit = units.get(casterCoords);
		
		target.alacrityPool.value += dalac;
		
		for (o in observers) o.alacUpdate(target, dalac, source);
	}
	
	public function castBuff(id:BuffID, targetCoords:UnitCoords, casterCoords:UnitCoords, duration:Int)
	{
		var target:Unit = units.get(targetCoords);
		var caster:Unit = units.get(casterCoords);
		
		if (targetCoords.equals(casterCoords))
			duration++;
		
		target.buffQueue.addBuff(new Buff(this, id, duration, targetCoords, casterCoords));
		
		for (o in observers) o.buffQueueUpdate(targetCoords, target.buffQueue.queue);
	}
	
	public function dispellBuffs(targetCoords:UnitCoords, ?elements:Array<Element>, ?count:Int = -1)
	{
		var target:Unit = units.get(targetCoords);
		
		target.buffQueue.dispellByElement(elements, count);
		
		for (o in observers) o.buffQueueUpdate(targetCoords, target.buffQueue.queue);
	}
	
	//================================================================================
    // Using Ability
    //================================================================================
	
	public function useRequest(login:String, abilityPos:Int, targetCoords:UnitCoords)
	{
		if (!checkTurn(login))
		{
			ConnectionManager.warn(login, "It's not your turn currently");
			return;
		}
		
		var chooseResult:ChooseResult = checkChoose(abilityPos);
		if (chooseResult != ChooseResult.Ok)
		{
			ConnectionManager.warn(login, switch (chooseResult)
			{
				case ChooseResult.Empty: "There is no ability in this slot";
				case ChooseResult.Manacost: "Not enough mana";
				case ChooseResult.Cooldown: "This ability is currently on cooldown";
				case ChooseResult.Passive: "This ability is passive, you can't use it";
				default: "";
			});
			return;
		}
		
		switch (checkTarget(targetCoords, abilityPos))
		{
			case TargetResult.Ok:
				useAbility(targetCoords, currentUnit, units.get(currentUnit).wheel.getActive(abilityPos));
			case TargetResult.Invalid:
				ConnectionManager.warn(login, "Chosen ability cannot be used on this target");
			default: //Skip
		}
	}
	
	private function useAbility(target:UnitCoords, caster:UnitCoords, ability:Active)
	{
		throwAb(target, caster, ability);
			
		var danmakuType:Null<AttackType> = ability.danmakuType();
		var pattern:String = "";
		if (danmakuType != null)
		{
			bhInfo = {ability:ability.id, caster: caster, element: ability.element};

			var selectedPattern:Int = selectedPatterns.get(caster)[ability.id];
			pattern = patterns.get(caster)[ability.id][selectedPattern];
		}

		var targets:Array<Unit> = ability.aoe? units.allied(target) : [units.get(target)];
		for (t in targets)
		{
			var tCoords:UnitCoords = UnitCoords.get(t);
			abilityTargets.push(tCoords);

			if (Utils.flipMiss(t, units.get(caster), ability))
			{
				for (o in observers) o.miss(tCoords, caster, ability.element);
				strikeFinished(tCoords);
			}
			else 
				strikeAb(tCoords, caster, ability, danmakuType, pattern, t.delayedPatterns);
		}
	}

	private function throwAb(target:UnitCoords, caster:UnitCoords, ability:Active)
	{
		ability.putOnCooldown();
		changeMana(caster, caster, -ability.manacost, Source.God);
		for (o in observers) o.abThrown(target, caster, ability.id, ability.type, ability.element);
	}

	private function strikeAb(target:UnitCoords, caster:UnitCoords, ability:Active, danmakuType:AttackType, pattern:String, delayedQueue:DelayedPatternQueue)
	{
		if (danmakuType == AttackType.Instant)
		{
			delayedQueue.flush();
			for (o in observers) o.abStriked(target, caster, ability.id, ability.type, ability.element, pattern);
			//TODO: Bot danamku
		}
		else 
		{
			if (danmakuType == AttackType.Delayed)
				delayedQueue.add(ability, pattern);
			for (o in observers) o.abStriked(target, caster, ability.id, ability.type, ability.element, pattern);
			Abilities.hit(this, ability.id, target, caster, ability.element);
			strikeFinished(target);
		}	
	}

	private function strikeFinished(target:UnitCoords) 
	{
		abilityTargets.remove(target);
		if (abilityTargets.empty())
		{
			bhInfo = null;
			postTurnProcess();
		}
	}

	//================================================================================
    // BH
    //================================================================================

	public function playerCollided(login:String)
	{
		boom(getUnit(login));
	}

	public function playerBHFinished(login:String)
	{
		bhOver(getUnit(login));
	}

	public function boom(coords:UnitCoords)
	{
		Abilities.hit(this, bhInfo.ability, coords, bhInfo.caster, bhInfo.element, ++bhHitsTaken[coords]);
		if (!bothTeamsAlive())
			end(defineWinner());
	}

	public function bhOver(coords:UnitCoords)
	{
		bhHitsTaken[coords] = 0;
		strikeFinished(coords);
	}

	//Maybe some validity checkers
	
    //================================================================================
    // Game cycle
    //================================================================================
	
	private function alacrityIncrement()
	{
		var alive:Unit->Bool = function(u:Unit){return u.isAlive();};
		var fastest:Array<Unit> = [];
		var fastestTurnCount:Int = 1000;
		for (unit in units.both.filter(alive))
		{
			var turns:Int = Math.ceil((unit.alacrityPool.maxValue - unit.alacrityPool.value) / getAlacrityGain(unit));
			if (turns < fastestTurnCount)
			{
				fastest = [unit];
				fastestTurnCount = turns;
			}
			else if (turns == fastestTurnCount)
				fastest.push(unit);
		}
		for (unit in units.both.filter(alive))
			changeAlacrity(UnitCoords.get(unit), UnitCoords.get(unit), getAlacrityGain(unit) * fastestTurnCount, Source.God);
				
		readyUnits = fastest;
		processReady();
	}
	
	private function processReady()
	{
		if (!Lambda.empty(readyUnits))
		{
			var index:Int = Math.floor(Math.random() * readyUnits.length);
			var unit:Unit = readyUnits[index];
			currentUnit = UnitCoords.get(unit);
			readyUnits = [];
			changeAlacrity(currentUnit, currentUnit, -unit.alacrityPool.value, Source.God);
			
			if (!unit.isStunned() && checkAlive([unit]))
			{
				if (!unit.isPlayer())
					botMakeTurn(unit);
				else
					room.player(unit).send("Turn");
			}
			else
				postTurnProcess();
		}
		else
			throw "Trying to process empty readyUnits array";
	}
	
	private function postTurnProcess()
	{
		var unit:Unit = units.get(currentUnit);
		
		if (!bothTeamsAlive()) 
		{
			end(defineWinner());
			return;
		}
			
		if (unit.isAlive())
		{
			for (o in observers) o.preTick(unit);
			var haveBuffs:Array<Unit> = units.both.filter(function(u){return !Lambda.empty(u.buffQueue.queue); });
			unit.tick();
			for (o in observers) o.tick(unit);
			for (o in observers) for (u in haveBuffs) o.buffQueueUpdate(UnitCoords.get(u), u.buffQueue.queue);
		}
			
		if (!bothTeamsAlive()) 
		{
			end(defineWinner());
			return;
		}
		
		alacrityIncrement();
	}
	
	private function botMakeTurn(bot:Unit)
	{
		var decision:BotDecision = Units.decide(this, bot.id);
		
		useAbility(decision.target, UnitCoords.get(bot), bot.wheel.getActive(decision.abilityNum));
	}
	
	private function getAlacrityGain(unit:Unit):Float
	{
		var sum:Float = 0;
		for (u in units.both)
			if (checkAlive([u]))
				sum += u.flow;
				
		return unit.flow / sum;
	}
	
	//================================================================================
    // Battle ending
    //================================================================================
	
	public function end(winner:Null<Team>)
	{
		var winners:Array<String> = [];
		var losers:Array<String> = [];
		var draw:Bool = winner == null;
		
		for (u in (units.getTeam(draw? Team.Left : winner))) 
			switch (u.id)
			{
				case UnitID.Player(pid): winners.push(pid);
				default:
			}
		for (u in (units.getTeam((winner == Team.Left || draw)? Team.Right : Team.Left))) 
			switch (u.id)
			{
				case UnitID.Player(pid): losers.push(pid);
				default:
			}
			
		onTerminate(winners, losers, draw);
	}
	
	private function defineWinner():Null<Team>
	{
		if (checkAlive(units.left))
			return Team.Left;
		else if (checkAlive(units.right))
			return Team.Right;
		else
			return null;
	}
	
	private function checkAlive(array:Array<Unit>):Bool
	{
		for (unit in array)
			if (unit.isAlive())
				return true;
		return false;
	}
	
	private function bothTeamsAlive():Bool
	{
		return checkAlive(units.left) && checkAlive(units.right);
	}
	
	//================================================================================
    // Special Input
    //================================================================================	
	
	public function skipTurn(peerID:String)
	{
		if (checkTurn(peerID))
		{
			changeAlacrity(currentUnit, currentUnit, -100, Source.God);
			postTurnProcess();
		}
	}
	
	public function quit(peerID:String)
	{
		for (u in units)
			switch (u.id)
			{
				case UnitID.Player(id): 
					if (id == peerID)
					{
						end(u.team == Team.Left? Team.Right : Team.Left);
						return;
					}
				default:
			}
		throw "Player not found";
	}
	
	//================================================================================
    // Checkers
    //================================================================================
	
	public function checkChoose(abilityPos:Int):ChooseResult
	{
		var ability:Ability = units.get(currentUnit).wheel.get(abilityPos);
		
		if (ability.checkEmpty())
			return ChooseResult.Empty;
		if (ability.type == AbilityType.Passive)
			return ChooseResult.Passive;
		
		var activeAbility:Active = units.get(currentUnit).wheel.getActive(abilityPos);
		
		if (activeAbility.checkOnCooldown())
			return ChooseResult.Cooldown;
		if (!units.get(currentUnit).checkManacost(abilityPos))
			return ChooseResult.Manacost;
		
		return ChooseResult.Ok;
	}
	
	public function checkTarget(targetCoords:UnitCoords, abilityPos:Int):TargetResult
	{
		var target:Unit = units.get(targetCoords);
		var caster:Unit = units.get(currentUnit);
		var ability:Active = units.get(currentUnit).wheel.getActive(abilityPos);
		
		if (target == null)
			return TargetResult.Nonexistent;
		if (target.hpPool.value == 0)
			return TargetResult.Dead;
		if (!ability.checkValidity(caster.figureRelation(target)))
			return TargetResult.Invalid;
			
		return TargetResult.Ok;
	}
	
    //================================================================================
	
	public function start()
	{
		alacrityIncrement();
	}
	
	public function new(allies:Array<Unit>, enemies:Array<Unit>, room:BattleRoom, onTerminate) 
	{
		this.onTerminate = onTerminate;
		this.room = room;
		this.units = new UPair(allies, enemies);
		this.readyUnits = [];
		this.bhHitsTaken = [for (u in allies.concat(enemies)) UnitCoords.get(u) => 0];
		this.patterns = new UPair([for (a in allies) new Map()], [for (e in enemies) new Map()]);
		this.selectedPatterns = new UPair([for (a in allies) new Map<AbilityID, Int>()], [for (e in enemies) new Map<AbilityID, Int>()]);
		for (u in units)
			for (abID in u.wheel.bhAbs())
			{
				patterns.getByUnit(u)[abID] = [];
				if (u.isPlayer())
					for (patternI in 0...3)
						patterns.getByUnit(u)[abID][patternI] = PlayerdataManager.instance.getPattern(abID, patternI, u.playerLogin());
					else
						patterns.getByUnit(u)[abID] = [Units.getPattern(u.id, abID)];
				selectedPatterns.getByUnit(u)[abID] = 0;
			}
				
		var effectHandler:EffectHandler = new EffectHandler();
		this.observers = [effectHandler, new EventSender(room)];
		effectHandler.init(this);
	}
	
}