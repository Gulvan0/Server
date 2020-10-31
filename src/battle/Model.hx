package battle;
import hl.types.ArrayObj;
import io.AbilityUtils;
import io.AbilityParser.AbilityProperites;
import battle.struct.EntityCoords;
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
using MathUtils;

enum AbilityAction
{
	General;
	Summoning;
	AttackOnSummon;
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
	var targets:Array<UnitCoords>;
};

/**
 * @author Gulvan
 */
class Model implements IInteractiveModel implements IMutableModel
{
	private var observers:Array<IModelObserver>;

	public var units(default, null):UPair<Unit>;
	public var summons(default, null):UPair<Null<Summon>>;
	public var currentUnit:UnitCoords;

	private var activeBH:Null<BHInfo>;

	private var playerLogins:Map<Team, Array<String>>;

	private var onTerminate:(winners:Array<String>, losers:Array<String>, ?draw:Bool)->Void;

	private var log:Bool = false;

	public function getUnits():UPair<Unit>
	{
		return units;
	}

	private function getEntity(coords:EntityCoords):Null<Entity>
	{
		var uc = coords.nearbyUnit();
		if (coords.summon)
			return summons.get(uc);
		else 
			return units.get(uc);
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
	
	private function getUnit(login:String):Null<UnitCoords>
	{
		for (u in units)
			switch (u.id) 
			{
				case UnitID.Player(l): 
					if (l == login)
						return u.coords;
				default:
			}
		return null;
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
					for (o in observers) o.shielded(targetCoords, source);
					return;
				}
			}
		}

		target.hpPool.value += dhp;	
		for (o in observers) o.hpUpdate(target, caster, dhp, element, crit, source);
		processPossibleDeath(target);
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
	
	public function castBuff(id:BuffID, targetCoords:UnitCoords, casterCoords:UnitCoords, duration:Int, ?properties:Map<String, String>, ?castedPassively:Bool = false)
	{
		var target:Unit = units.get(targetCoords);
		var caster:Unit = units.get(casterCoords);
		
		if (targetCoords.equals(casterCoords) && !castedPassively)
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

	public function summon(s:Summon, position:EntityCoords)
	{
		summons.set(position, s);
		for (o in observers) o.summonAppeared(position, s.id, s.hp);
		for (aura in units.any(position.team).auraQueue.queue) //Dirty hack (either everyone or noone from the same team affected & any aura will affect units & while the game isn't over, there is at least one unit in each team)
			if (AbilityManager.auras.get(aura.id).affectsSummons)
				castAuraOn(aura.id, aura.level, aura.owner, s);
			
		SummonActions.act(this, s.id, position, Summoned, s.level);
	}

	public function applyAura(id:AbilityID, level:Int, owner:EntityCoords)
	{
		var auraData = AbilityManager.auras.get(id);
		var affectedRel = auraData.affectedTeams;
		var affectedAbs = affectedRel.map(t -> owner.absoulteTeam(t));
		for (team in affectedAbs)
		{
			var entitiesToAffect:Array<Entity> = units.getTeam(team);
			if (auraData.affectsSummons)
				entitiesToAffect = entitiesToAffect.concat(summons.getTeam(team));
			for (entity in entitiesToAffect)
				castAuraOn(id, level, owner, entity);
		}
	}

	private function castAuraOn(id:AbilityID, level:Int, owner:EntityCoords, affected:Entity) 
	{
		var effect = new AuraEffect(id, level, owner);
		affected.auraQueue.add(effect, this, affected);
		for (o in observers) o.auraApplied(id, owner, affected.coords);
	}

	//Doesn't belong to mutable
	private function removeAuras(owner:EntityCoords)
	{
		for (entity in units.both.concat(summons.both))
			entity.auraQueue.remove(owner, this, entity);
		for (o in observers) o.aurasRemoved(owner);
	}
	
	//================================================================================
    // Using Ability
    //================================================================================
	
	public function useRequest(login:String, abilityPos:Int, targetCoords:EntityCoords)
	{
		var casterCoords = getUnit(login);
		var caster = units.get(casterCoords);
		var abID = caster.wheel.abilities[abilityPos];

		if (!AbilityManager.actives.exists(abID))
			return;

		var ability:AbilityProperites = AbilityManager.abilities.get(abID);
		var activeAbility:Active = caster.wheel.actives.get(abID);

		if (!activeAbility.checkOnCooldown() && caster.checkManacost(abilityPos))
			if (ability.type == BHSkill)
				throwAb(targetCoords, casterCoords, abilityPos);
			else if (checkTurn(login))
			{
				var action = checkAndResolveAction(targetCoords, casterCoords, ability.type, activeAbility);
				if (action != null)
				{
					throwAb(targetCoords, casterCoords, abilityPos);
					useAbility(targetCoords, casterCoords, wheel.actives.get(abID), action);
				}
			}
	}

	public function checkAndResolveAction(target:EntityCoords, caster:UnitCoords, abType:AbilityType, ability:Active):Null<AbilityAction>
	{
		var uc = target.nearbyUnit();
		var targetedUnit = units.get(uc);
		var targetedSummon = summons.get(uc);
		if (abType == Summon)
		{
			if (target.summon && targetedSummon == null)
				return Summoning;
		}
		else 
			if (target.summon && targetedSummon != null && ability.validForSummon())
				return AttackOnSummon;
			else if (!target.summon && targetedUnit != null && ability.validForUnit(caster.figureRelation(target)))
				return General;
		return null;
	}
	
	private function useAbility(target:EntityCoords, caster:UnitCoords, ability:Active, action:AbilityAction)
	{
		switch action 
		{
			case General:
				useGeneral(target, caster, ability);
			case Summoning:
				Abilities.hit(this, ability.id, ability.level, target, caster, ability.element);
				postTurnProcess();
			case AttackOnSummon:
				var targetedSummon = summons.get(target.nearbyUnit());
				if (targetSummon.shields.penetrate(1) > 0)
				{
					for (o in observers) o.abStriked(target, true, caster, ability, ""); //TODO: Change notifications signatures
					targetSummon.decrementHP();
					processPossibleDeath(target);
				}
				else 
					for (o in observers) o.shielded(target, true, Source.Ability);
				postTurnProcess();
		}
	}

	private function useGeneral(target:EntityCoords, caster:UnitCoords, ability:Active)
	{
		var c = units.get(caster);
		var danmakuProps = AbilityManager.danmaku.get(ability.id);
		var targets:Array<Unit> = buildTargets(target, ability);
		if (danmakuProps != null)
		{
			activeBH = {ability:ability.id, caster: caster, element: AbilityManager.abilities.get(ability.id).element, level: ability.level, targets: []};

			for (t in targets)
				if (Utils.flipMiss(t, c, ability, log))
					for (o in observers) o.miss(t.coords, false, caster, ability.element);
				else 
				{
					activeBH.targets.push(t.coords);
					strikeDanmaku(t.coords, caster, ability, danmakuProps.danmakuType, c.getPattern(ability.id), t.delayedPatterns);
				}
			checkBHOver();
		}
		else 
		{
			for (t in targets)
				if (Utils.flipMiss(t, c, ability, log))
					for (o in observers) o.miss(t.coords, false, caster, ability.element);
				else
					strikeNonDanmaku(t.coords, caster, ability);
			postTurnProcess();
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

	private function throwAb(target:EntityCoords, caster:UnitCoords, ability:Active)
	{
		ability.putOnCooldown();
		changeMana(caster, caster, -ability.manacost, Source.God);
		for (o in observers) o.abThrown(target, caster, ability.id, ability.type, ability.element);
	}

	private function strikeDanmaku(target:UnitCoords, caster:UnitCoords, ability:Active, danmakuType:AttackType, pattern:String, delayedQueue:DelayedPatternQueue)
	{
		if (danmakuType == Instant)
			delayedQueue.flush();
		else 
			delayedQueue.add(ability, pattern);

		for (o in observers) o.abStriked(target, false, caster, ability, pattern);
		if (danmakuType == Delayed)
			Abilities.hit(this, ability.id, ability.level, target, caster, ability.element);
	}

	private function strikeNonDanmaku(target:UnitCoords, caster:UnitCoords, ability:Active)
	{
		for (o in observers) o.abStriked(target, false, caster, ability, "");
		Abilities.hit(this, ability.id, ability.level, target, caster, ability.element);
	}

	//================================================================================
    // BH
    //================================================================================

	public function playerCollided(login:String)
	{
		var coords = getUnit(login);
		if (abilityTargets.has(coords))
		{
			Abilities.hit(this, activeBH.ability, activeBH.level, coords, activeBH.caster, activeBH.element);
			if (units.get(coords) == null)
				strikeFinished(coords);
		}
	}

	public function playerBHFinished(login:String)
	{
		activeBH.targets.removeOn(c->c.equals(getUnit(login)));
		checkBHOver();
	}

	private function checkBHOver() 
	{
		if (activeBH.targets.empty())
		{
			activeBH = null;
			postTurnProcess();
		}
	}
	
    //================================================================================
    // Game cycle
    //================================================================================
	
	private function alacrityIncrement()
	{
		var aliveUnits = units.both;
		var totalSpeed = aliveUnits.sum(u->u.speed);
		var min = aliveUnits.argmin(u->u.iterationsToFullAlac(totalSpeed));
		if (min.val > 0)
			for (unit in aliveUnits)
				changeAlacrity(unit.coords, unit.coords, unit.alacGain(totalSpeed) * min.val, God);
				
		processReady(min.arg);
	}
	
	private function processReady(readyUnits:Array<Unit>)
	{
		var unit:Unit = readyUnits.rand();
		currentUnit = unit.coords;
		changeAlacrity(currentUnit, currentUnit, -unit.alacrityPool.value, God);
			
		if (!unit.isStunned() && unit.canMakeTurn())
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
		{
			SummonActions.act(this, actingSummon.id, currentUnit, SummonEvent.OverTime, actingSummon.level);
			for (aura in actingSummon.auraQueue.queue)
				Auras.act(aura, this, actingSummon, OverTime);
		}

		if (unit != null)
		{
			for (o in observers) o.preTick(unit);

			unit.tick();
			unit.buffQueue.state = BuffQueueState.OthersTurn;
			for (aura in unit.auraQueue.queue)
				Auras.act(aura, this, unit, OverTime);

			for (o in observers) o.tick(unit);

			processPossibleDeath(unit);
		}
			
		if (!bothTeamsAlive())
			end(defineWinner());
		else
			alacrityIncrement();
	}
	
	private function botMakeTurn(bot:Unit)
	{
		//TODO: [PvE Update] Implement
	}

	private function processPossibleDeath(coords:EntityCoords)
	{
		if (!getEntity(coords).isAlive())
		{
			if (coords.summon)
				summons.nullify(coords.nearbyUnit());
			else 
				units.nullify(coords.nearbyUnit());

			removeAuras(coords);
			for (o in observers) o.death(coords);
		}
	}
	
	//================================================================================
    // Battle ending
    //================================================================================
	
	public function end(winner:Null<Team>)
	{
		//TODO: [Ranked Update] Add records if ranked
		if (winner != null)
			onTerminate(playerLogins[winner], playerLogins[Utils.oppositeTeam(winner)], false);
		else 
			onTerminate(playerLogins[Left], playerLogins[Right], true);
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
	
	public function start()
	{
		for (u in units)
			for (i in u.wheel.auraIndexes())
				applyAura(u.wheel.abilities[i], u.wheel.levels[i], u.coords);
		alacrityIncrement();
	}
	
	public function new(allies:Array<Unit>, enemies:Array<Unit>, room:BattleRoom, onTerminate) 
	{
		this.onTerminate = onTerminate;
		this.units = new UPair(allies, enemies);
		this.summons = new UPair([null, null, null], [null, null, null]);
		this.playerLogins = [Left => extractLogins(allies), Right => extractLogins(enemies)];
				
		var effectHandler:EffectHandler = new EffectHandler();
		effectHandler.init(this);
		this.observers = [effectHandler, new EventSender(room)];

		#if logbattles
		this.observers.push(new Logger(getUnits));
		log = true;
		#end
	}

	private function extractLogins(units:Array<Unit>) 
	{
		return units.map(u -> u.playerLogin()).filter(l -> (l != null));
	}
	
}