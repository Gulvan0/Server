package managers;

import battle.enums.Attribute;
import battle.Unit.ParameterList;
import managers.AbilityManager.TreePos;
import haxe.Json;
import sys.thread.Thread;
import ID.AbilityID;
import io.Tree;
import hxassert.Assert;
import json2object.JsonParser;
import sys.io.File;
import sys.FileSystem;
using MathUtils;

typedef CharData = 
{
    var name:String;
    var element:String;
    var xp:Int;
    var level:Int;
    var abp:Int;
    var attp:Int;
    var s:Int;
    var f:Int;
    var i:Int;
    var wheel:Array<String>;
    var tree:Array<Array<Int>>;
}

typedef Playerdata = 
{
    var character:CharData;
    var rating:Int;
}

class PlayerdataManager
{
    public static var instance:PlayerdataManager;
    public var cache(default, null):Map<String, Playerdata>;

    public function learnAbility(i:Int, j:Int, login:String):Bool
    {
        Assert.require(i.inRange(0, GameRules.treeHeight - 1));
        Assert.require(j.inRange(0, GameRules.treeWidth - 1));
        Assert.assert(cache.exists(login));
        var char = cache.get(login).character;
        var tree:Tree = AbilityManager.trees.get(Element.createByName(char.element));
        var id:AbilityID = tree.getID(i, j);
        
        if (char.abp == 0)
            return false;
        
		if (char.tree[i][j] == AbilityManager.abilities.get(id).maxlvl)
            return false;
        
        for (deltaI in tree.getReqDeltas(i, j))
			if (char.tree[i + deltaI][j - 1] == 0)
				return false;
        
        char.abp--;
        Thread.create(updatePlayer.bind(login));
        return true;
    }

    public function putAbility(ability:AbilityID, pos:Int, login:String):Bool
	{
        var char = cache.get(login).character;
		var abCoords:Null<TreePos> = AbilityManager.findAbility(ability);
		if (abCoords == null || char.tree[abCoords.i][abCoords.j] == 0)
            return false;
        
		removeFromWheelByID(ability, char);
        Thread.create(updatePlayer.bind(login));
		return true;
    }

    public function removeFromWheel(pos:Int, login:String) 
    {
        var char = cache.get(login).character;
        removeFromWheelByPos(pos, char);
        Thread.create(updatePlayer.bind(login));
    }

    public function incrementAtt(a:Attribute, login:String)
	{
        var char = cache.get(login).character;
		if (char.attp > 0)
		{
            switch a 
            {
                case Strength: char.s++;
                case Flow: char.f++;
                case Intellect: char.i++;
            }
            char.attp--;
            Thread.create(updatePlayer.bind(login));
        }
    }
    
    public function reSpec(login:String)
	{
        var char = cache.get(login).character;
        var element = Element.createByName(char.element);
        var bonus:Map<Attribute, Int> = GameRules.attributeLvlupBonus(element);
        var timesRewarded:Int = char.level - 1;
        char.s = GameRules.initialAttributeValues + bonus[Strength] * timesRewarded;
        char.f = GameRules.initialAttributeValues + bonus[Flow] * timesRewarded;
        char.i = GameRules.initialAttributeValues + bonus[Intellect] * timesRewarded;
		
		char.tree = [for (i in 0...GameRules.treeHeight) [for (j in 0...GameRules.treeWidth) 0]];
		char.wheel = [];
		
		char.abp = GameRules.initialAbilityPoints + GameRules.abPointsLvlupBonus() * timesRewarded;
        char.attp = GameRules.initialAttributePoints + GameRules.attPointsLvlupBonus() * timesRewarded;
        
        Thread.create(updatePlayer.bind(login));
    }
    
    public function getPattern(id:AbilityID, pos:Int, login:String):String
    {
        Assert.assert(pos >= 0 && pos <= 2);
        return File.getContent(patternPath(login, id, pos));
    }

    public function setPattern(id:AbilityID, pos:Int, pattern:String, login:String)
    {
        Assert.assert(pos >= 0 && pos <= 2);
        File.saveContent(patternPath(login, id, pos), pattern);
    }

    public function gainXP(amount:Int, login:String) 
    {
        var char = cache.get(login).character;
        var levelsGained = 0;
        var xpLeftToLvl = GameRules.xpToLvlup(char.level) - char.xp; 

        while (amount >= xpLeftToLvl)
        {
            amount -= xpLeftToLvl;
            char.level++;
            char.xp = 0;
            xpLeftToLvl = GameRules.xpToLvlup(char.level);
            levelsGained++;
        }
        char.xp = amount;

        var bonus =  GameRules.attributeLvlupBonus(Element.createByName(char.element));
        char.s += bonus[Strength] * levelsGained;
        char.f += bonus[Flow] * levelsGained;
        char.i += bonus[Intellect] * levelsGained;
        char.abp += GameRules.abPointsLvlupBonus() * levelsGained;
        char.attp += GameRules.attPointsLvlupBonus() * levelsGained;

        Thread.create(updatePlayer.bind(login));
    }

    public function earnRating(amount:Null<Int>, login:String) 
    {
        if (amount == null)
            return;

        cache.get(login).rating += amount;
        Thread.create(updatePlayer.bind(login));
    }

    public function extractParams(login:String):ParameterList
    {
        var char = cache.get(login).character;
        var wheel:Array<AbilityID> = [];
        var abilityLevels:Map<AbilityID, Int> = [];
        for (idStr in char.wheel)
        {
            var id:AbilityID = AbilityID.createByName(idStr);
            var abPos:TreePos = AbilityManager.findAbility(id);
            wheel.push(id);
            abilityLevels.set(id, char.tree[abPos.i][abPos.j]);
        }
        return {
            name: char.name,
            element: Element.createByName(char.element),
            hp: GameRules.basicHP + GameRules.hpStBonus(char.s),
            mana: GameRules.basicMana + GameRules.manaInBonus(char.i),
            wheel: wheel,
            abilityLevels: abilityLevels,
            strength: char.s,
            flow: char.f,
            intellect: char.i
        };
    }
    //? Add in alpha 5.0: getCompletedStageCount, canVisit, proceed, isAtBossStage
    
    //=====================================================================================================================================================

    private function removeFromWheelByPos(pos:Int, char:CharData)
	{
        Assert.assert(pos.inRange(0, GameRules.wheelSlotCount(char.level)));
        char.wheel[pos] = EmptyAbility.getName();
	}
    
    private function removeFromWheelByID(id:AbilityID, char:CharData)
	{
        var pos:Int = char.wheel.indexOf(id.getName());
        if (pos != -1)
            removeFromWheelByPos(pos, char);
	}
    
    //=====================================================================================================================================================
    
    //TODO: Call on register
    public function loadPlayer(login:String) 
    {
        var path = pdPath(login);
        if (FileSystem.exists(path))
        {
            var content = File.getContent(path);
            var parser:JsonParser<Playerdata> = new JsonParser<Playerdata>();
            parser.fromJson(content);
            cache.set(login, parser.value);
        }
    }

    public function updatePlayer(login:String) 
    {
        var path = PlayerdataManager.pdPath(login);
        var newdata:String = Json.stringify(cache.get(login), null, "\t");
        File.saveContent(path, newdata);
    }

    //TODO: Call on disconnect
    public function unloadPlayer(login:String) 
    {
        cache.remove(login);
    }

    public static inline function pdPath(login:String):String
    {
        return Main.playersDir + login + "\\" + login + ".json";
    }

    public static inline function patternPath(login:String, ability:AbilityID, pos:Int):String
    {
        return Main.playersDir + login + "\\patterns\\" + ability.getName() + "\\" + (pos+1) + ".json";
    }

    public function new() 
    {
        cache = [];
        instance = this;
    }
}