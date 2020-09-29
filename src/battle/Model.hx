package battle;
import battle.data.SummonActions;
import ID.SummonID;
import battle.enums.AbilityTarget;
import managers.AbilityManager;
import io.AbilityParser.AbilityFlag;
import hxassert.Assert;
import battle.struct.BuffQueue.BuffQueueState;
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
import battle.data.Auras;
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
	var level:Int;
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
	public var summons(default, null):UPair<Null<Summon>>;
	public var auras(default, null):Map<Team, Array<Aura>>;
	public var currentUnit:UnitCoords;
	
	private var readyUnits:Array<Unit>;

	private var abilityTargets:Array<UnitCoords> = [];
	private var bhInfo:Null<BHInfo> = null;
	private var bhHitsTaken:Map<UnitCoords, Int> = [];

	private var patterns:UPair<Map<AbilityID, Array<String>>>;
	private var selectedPatterns:UPair<Map<AbilityID, Int>>;

	private var onTerminate:(winners:Array<String>, losers:Array<String>, ?draw:Bool)->Void;

	private var log:Bool = false;

	public function getUnits():UPair<Unit>
	{
		return units;
	}

	public function toString():String
	{
		var writer:JsonWriter<Unit> = new JsonWriter<Unit>();
		var s = '';
		for (u in units)
			s += writer.write(u, '\t') + '\n________________\n';
		s += 'Current: ' + haxe.Json.stringify(currentUnit);
		return s;
	}
	
	public function getBattleData(login:String):String
	{
		var requesterCoords = getUnit(login);
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
		}], personal: units.get(requesterCoords).wheel.getlwArray(patterns.get(requesterCoords))});
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

	public function selectPattern(login:String, ability:AbilityID, ptnPos:Int)
	{
		if (ptnPos >= 0 && ptnPos < 3)
			selectedPatterns.get(getUnit(login)).set(ability, ptnPos);
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
			dhp = Utils.calcBoostedDHP(dhp, caster, target);
			if (source == Source.Ability)
			{
				var updatedValue = caster.rollCrit(dhp, log);
				crit = dhp != updatedValue;
				dhp = updatedValue;
			}
			if (dhp < 0)
			{
				dhp = -target.shields.penetrate(-dhp);
				if (dhp == 0)
				{
					for (o in observers) o.shielded(targetCoords, false, source);
					return;
				}
			}
		}

		target.hpPool.value += dhp;	
		for (o in observers) o.hpUpdate(target, caster, dhp, element, crit, source);
		processPossibleDeath(target);
	}

	private function processPossibleDeath(target:Unit) 
	{
		var targetCoords = UnitCoords.get(target);
		if (!target.isAlive())
		{
			for (aura in auras[Left].concat(auras[Right]))
				if (aura.owner.equals(currentUnit) && !aura.summonOwner)
					removeAura(aura);
			for (o in observers) o.death(targetCoords);
		}
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
	
	public function castBuff(id:BuffID, targetCoords:UnitCoords, casterCoords:UnitCoords, duration:Int, ?properties:Map<String, String>)
	{
		var target:Unit = units.get(targetCoords);
		var caster:Unit = units.get(casterCoords);
		
		if (targetCoords.equals(casterCoords))
			duration++;
		
		target.buffQueue.addBuff(new Buff(this, id, duration, targetCoords, casterCoords, properties));
		
		for (o in observers) o.buffQueueUpdate(targetCoords, target.buffQueue.queue);
	}
	
	public function dispellBuffs(targetCoords:UnitCoords, ?elements:Array<Element>, ?count:Int)
	{
		var target:Unit = units.get(targetCoords);
		
		if (target.buffQueue.dispellByElement(elements, count))
			for (o in observers) o.buffQueueUpdate(targetCoords, target.buffQueue.queue);
	}

	public function summon(s:Summon, position:UnitCoords) 
	{
		summons.set(position, s);
		for (o in observers) o.summonAppeared(position, s.id);
		for (aura in auras.get(position.team))
			if (aura.affectsSummons)
				Auras.activateForSummon(aura, this, position);
		SummonActions.act(this, s.id, new UnitCoords(s.team, s.position), SummonEvent.Summoned, s.level);
	}

	public function applyAura(aura:Aura) 
	{
		auras.get(aura.getAffectedTeam()).push(aura);
		Auras.activate(aura, this);
		for (o in observers) o.auraApplied(new UnitCoords(aura.owner.team, aura.owner.pos), aura.id);
	}

	//Doesn't belong to mutable
	private function removeAura(aura:Aura) 
	{
		auras.get(aura.getAffectedTeam()).remove(aura);
		Auras.deactivate(aura, this);
		for (o in observers) o.auraRemoved(new UnitCoords(aura.owner.team, aura.owner.pos), aura.id);
	}
	
	//================================================================================
    // Using Ability
    //================================================================================
	
	public function useRequest(login:String, abilityPos:Int, targetCoords:UnitCoords, summon:Bool)
	{
		var casterCoords = getUnit(login);
		var ability = units.get(casterCoords).wheel.get(abilityPos);
		if (!checkTurn(login) && ability.type != BHSkill)
			return;
		
		if (checkChoose(abilityPos, casterCoords) != Ok)
			return;
		
		if (checkTarget(targetCoords, casterCoords, abilityPos, summon) == Ok)
			useAbility(targetCoords, casterCoords, cast ability, summon);
	}
	
	private function useAbility(target:UnitCoords, caster:UnitCoords, ability:Active, summon:Bool)
	{
		throwAb(target, summon, caster, ability);
		if (ability.type == BHSkill)
			return;

		if (summon)
		{
			if (ability.type != Summon)
			{
				var targetSummon = summons.get(target);
				Assert.assert(targetSummon != null);
				if (Math.random() >= targetSummon.evasionChance.apply(1))
				{
					for (o in observers) o.miss(target, true, caster, ability.element);
					return;
				}
				if (targetSummon.shields.penetrate(1) == 0)
				{
					for (o in observers) o.shielded(target, true, Source.Ability);
					return;
				}
				for (o in observers) o.abStriked(target, true, caster, ability, "");
				targetSummon.decrementHP();
				if (targetSummon.dead())
				{
					summons.nullify(target);
					for (o in observers) o.summonDead(target);
					for (aura in auras[Left].concat(auras[Right]))
						if (aura.owner.equals(target) && aura.summonOwner)
							removeAura(aura);
				}
			}
			else if (summons.get(target) == null)
				Abilities.hit(this, ability.id, ability.level, target, caster, ability.element);
			postTurnProcess();
			return;
		}
			
		var danmakuType:Null<AttackType> = ability.danmakuType();
		var pattern:String = "";
		if (danmakuType != null)
		{
			bhInfo = {ability:ability.id, caster: caster, element: ability.element, level: ability.level};

			var selectedPattern:Int = selectedPatterns.get(caster)[ability.id];
			pattern = patterns.get(caster)[ability.id][selectedPattern];
		}

		var targets:Array<Unit> = buildTargets(target, ability);
		for (t in targets)
		{
			var tCoords:UnitCoords = UnitCoords.get(t);
			abilityTargets.push(tCoords);

			if (Utils.flipMiss(t, units.get(caster), ability, log))
			{
				for (o in observers) o.miss(tCoords, false, caster, ability.element);
				strikeFinished(tCoords);
			}
			else 
				strikeAb(tCoords, caster, ability, danmakuType, pattern, t.delayedPatterns);
		}
	}

	private function buildTargets(target:UnitCoords, ability:Active):Array<Unit>
	{
		for (flag in ability.flags)
			switch flag 
			{
				case AOE: return units.allied(target);
				case Multistrike(count): return [for (i in 0...count) units.get(target)];
				default:
			}
		return [units.get(target)];
	}

	private function throwAb(target:UnitCoords, summon:Bool, caster:UnitCoords, ability:Active)
	{
		ability.putOnCooldown();
		changeMana(caster, caster, -ability.manacost, Source.God);
		for (o in observers) o.abThrown(target, summon, caster, ability.id, ability.type, ability.element);
	}

	private function strikeAb(target:UnitCoords, caster:UnitCoords, ability:Active, danmakuType:AttackType, pattern:String, delayedQueue:DelayedPatternQueue)
	{
		if (danmakuType == AttackType.Instant)
		{
			delayedQueue.flush();
			for (o in observers) o.abStriked(target, false, caster, ability, pattern);
			//TODO: [PvE Update] Bot danamku
		}
		else 
		{
			if (danmakuType == AttackType.Delayed)
				delayedQueue.add(ability, pattern);
			for (o in observers) o.abStriked(target, false, caster, ability, pattern);
			Abilities.hit(this, ability.id, ability.level, target, caster, ability.element);
			strikeFinished(target);
		}	
	}

	private function strikeFinished(target:UnitCoords) 
	{
		for (i in 0...abilityTargets.length)
			if (abilityTargets[i].equals(target))
				abilityTargets.splice(i, 1);
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
		Abilities.hit(this, bhInfo.ability, bhInfo.level, coords, bhInfo.caster, bhInfo.element, ++bhHitsTaken[coords]);
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
		Assert.require(!Lambda.empty(readyUnits));
		
		var index:Int = Math.floor(Math.random() * readyUnits.length);
		var unit:Unit = readyUnits[index];
		currentUnit = UnitCoords.get(unit);
		readyUnits = [];
		changeAlacrity(currentUnit, currentUnit, -unit.alacrityPool.value, Source.God);
			
		if (!unit.isStunned() && hasAvailableAbility(currentUnit) && checkAlive([unit]))
		{
			unit.buffQueue.state = BuffQueueState.OwnersTurn;
			for (o in observers) o.turn(unit);
			if (!unit.isPlayer())
				botMakeTurn(unit);
		}
		else
			postTurnProcess();
	}
	
	private function postTurnProcess()
	{
		var unit:Unit = units.get(currentUnit);

		var actingSummon = summons.get(currentUnit);
		if (actingSummon != null)
			SummonActions.act(this, actingSummon.id, currentUnit, SummonEvent.OverTime, actingSummon.level);

		if (unit.isAlive())
		{
			for (o in observers) o.preTick(unit);

			unit.tick();
			unit.buffQueue.state = BuffQueueState.OthersTurn;
			for (aura in auras.get(unit.team))
				Auras.overtime(aura, this, currentUnit);	

			for (o in observers) o.tick(unit);

			for (aura in auras[Left].concat(auras[Right]))
				if (aura.owner.equals(currentUnit)) //Both for an unit and a summon
					aura.incrDuration();

			processPossibleDeath(unit);
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
		/*var decision:BotDecision = Units.decide(this, bot.id);
		
		useAbility(decision.target, UnitCoords.get(bot), bot.wheel.getActive(decision.abilityNum));*///TODO: [PvE Update] Rewrite
	}
	
	private function getAlacrityGain(unit:Unit):Float
	{
		var sum:Float = 0;
		for (u in units.both)
			if (checkAlive([u]))
				sum += u.speed;
				
		return unit.speed / sum;
	}
	
	//================================================================================
    // Battle ending
    //================================================================================
	
	public function end(winner:Null<Team>)
	{
		//TODO: [Ranked Update] Add records if ranked
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
			for (o in observers) o.pass(currentUnit);
			changeAlacrity(currentUnit, currentUnit, -100, Source.God);
			postTurnProcess();
		}
	}
	
	public function quit(peerID:String) //TODO: [Team Update] Update
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
		Assert.fail("Player not found");
	}
	
	//================================================================================
    // Checkers
    //================================================================================
	
	private function hasAvailableAbility(coords:UnitCoords):Bool
	{
		var u:Unit = units.get(coords);
		for (i in 0...u.wheel.numOfSlots)
		{
			if (checkChoose(i, coords) == Ok)
				if (u.wheel.get(i).type != BHSkill)
					return true;
		}
		return false;
	}
	
	private function checkChoose(abilityPos:Int, casterCoords:UnitCoords):ChooseResult
	{
		var ability:Ability = units.get(casterCoords).wheel.get(abilityPos);
		
		if (ability.checkEmpty())
			return ChooseResult.Empty;
		if (ability.type == AbilityType.Passive)
			return ChooseResult.Passive;
		
		var activeAbility:Active = cast ability;
		
		if (activeAbility.checkOnCooldown())
			return ChooseResult.Cooldown;
		if (!units.get(casterCoords).checkManacost(abilityPos))
			return ChooseResult.Manacost;
		
		return ChooseResult.Ok;
	}
	
	private function checkTarget(targetCoords:UnitCoords, casterCoords:UnitCoords, abilityPos:Int, summon:Bool):TargetResult
	{
		var caster:Unit = units.get(casterCoords);
		var ability:Active = caster.wheel.getActive(abilityPos);

		if (summon)
		{
			var targetSummon = summons.get(targetCoords);
			if (targetSummon == null && ability.type != Summon)
				return Nonexistent;
			else if (ability.type == Summon)
				if (targetSummon != null)
					return Invalid;
				else
					return Ok;
			else if (![All, Enemy].has(ability.possibleTarget))
				return Invalid;
			else 
				return Ok;
		}

		var target:Unit = units.get(targetCoords);
		
		if (ability.type == BHSkill)
			return Ok;
		if (target == null)
			return Nonexistent;
		if (target.hpPool.value == 0)
			return Dead;
		if (!ability.checkValidity(caster.figureRelation(target)))
			return Invalid;
			
		return Ok;
	}
	
    //================================================================================
	
	public function start()
	{
		for (u in units)
			for (aura in u.wheel.auras(UnitCoords.get(u)))
				applyAura(aura);
		alacrityIncrement();
	}
	
	public function new(allies:Array<Unit>, enemies:Array<Unit>, room:BattleRoom, onTerminate) 
	{
		this.onTerminate = onTerminate;
		this.room = room;
		this.units = new UPair(allies, enemies);
		this.summons = new UPair([null, null, null], [null, null, null]);
		this.auras = [Left => [], Right => []];
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
		effectHandler.init(this);
		this.observers = [effectHandler, new EventSender(room)];

		#if logbattles
		this.observers.push(new Logger(getUnits));
		log = true;
		#end
	}
	
}