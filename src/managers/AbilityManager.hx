package managers;

import hxassert.Assert;
import io.AbilityParser;
import battle.Aura;
import io.AbilityParser.Ability;
import ID.AbilityID;
import io.Tree;
import io.TreeParser;

typedef TreePos = {i:Int, j:Int};

enum RelativeTeam
{
    Allied;
    Enemy;
}

class AbilityManager 
{
    public static var abilities(default, null):Map<AbilityID, AbilityProperties> = [];
    public static var actives(default, null):Map<AbilityID, ActiveProperties> = [];
    public static var passives(default, null):Map<AbilityID, PassiveProperties> = [];
    public static var auras(default, null):Map<AbilityID, AuraProperties> = [];
    public static var danmaku(default, null):Map<AbilityID, DanmakuProperties> = [];
    public static var trees(default, null):Map<Element, Tree>;

    public static function findAbility(id:AbilityID):Null<TreePos>
    {
        var element:Element = abilities.get(id).element;
        var tree:Tree = trees.get(element);
        for (i in 0...GameRules.treeHeight)
            for (j in 0...GameRules.treeWidth)
                if (tree.getID(i, j) == id)
                    return {i:i, j:j};
        return null;
    }

    public function reactsTo(passive:AbilityID, event:BattleEvent):Bool
	{
        var ab:PassiveProperties = passives.get(id);
        Assert.assert(ab != null);
        return Lambda.has(ab.triggers, event);
    }

    public static function init() 
    {
        var parser:AbilityParser = new AbilityParser();
        parser.initMaps();
        abilities = parser.abilities;
        actives = parser.actives;
        danmaku = parser.danmaku;
        passives = parser.passives;
        auras = parser.auras;
        trees = TreeParser.createMap();
    }
}