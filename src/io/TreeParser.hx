package io;

import haxe.Json;
import sys.io.File;
import sys.FileSystem;

class TreeParser 
{
    public static function createMap():Map<Element, Tree>
    {
        var map:Map<Element, Tree> = [];

        for (e in Element.createAll())
        {
            var path = Main.gamedataDir + AbilityUtils.getElementAbbreviation(e) + "\\abilities.json";
            if (!FileSystem.exists(path))
                continue;

            var tree:Tree = Json.parse(File.getContent(path));
            map.set(e, tree);
        }
        return map;
    }
}