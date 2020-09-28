package managers;

import io.AbilityParser;
import battle.Aura;
import io.AbilityParser.Ability;
import ID.AbilityID;
import io.Tree;
import io.TreeParser;

typedef TreePos = {i:Int, j:Int};

class AbilityManager 
{
    public static var abilities(default, null):Map<AbilityID, Ability>;
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

    public static function init() 
    {
        io.AbilityParser.initMaps();
        abilities = AbilityParser.abilities;
        trees = TreeParser.createMap();
    }
}