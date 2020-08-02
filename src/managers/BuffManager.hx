package managers;

import io.AbilityUtils;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import hxassert.Assert;
import ID.BuffID;
import battle.data.Passives.BattleEvent;

enum BuffFlag 
{
    Overtime;
    Stun;
    Silence;
    Stackable;
    Morph;
    Undispellable;
    Danmaku;    
}

typedef ParsedBuff =
{
    var name:String;
    var rawDesc:String;
    var flags:Array<BuffFlag>;
    var triggers:Array<BattleEvent>;
    var element:Element;
}

class BuffManager
{
    public static var buffs(default, null):Map<BuffID, ParsedBuff>;
    
    public static function init() 
    {
        for (element in Element.createAll())
        {
            var path = Main.gamedataDir + AbilityUtils.getElementAbbreviation(element) + "\\buffs.json";
            if (!FileSystem.exists(path))
                continue;

            var full = Json.parse(File.getContent(path));
            for (prop in Reflect.fields(full))
            {
                var id:BuffID = BuffID.createByName(prop);
                var buffObj = Reflect.field(full, prop);
                buffs.set(id, initBuff(buffObj, id, element));
            }
        }    
    }

    private static function initBuff(obj:Dynamic, id:BuffID, element:Element):ParsedBuff
    {
        Assert.assert(Reflect.hasField(obj, "description"));
        var flags:Array<BuffFlag> = [];
        if (Reflect.hasField(obj, "flags"))
        {
            var flagStrs:Array<String> = Reflect.field(obj, "flags");
            for (flag in flagStrs)
            {
                var flagName = flag.charAt(0).toUpperCase() + flag.substr(1);
                var flagEnumValue = BuffFlag.createByName(flagName);
                flags.push(flagEnumValue);
            }
        }

        var triggers:Array<BattleEvent> = [];
        if (Reflect.hasField(obj, "triggers"))
        {
            var trg:Array<String> = Reflect.field(obj, "triggers");
            triggers = trg.map(BattleEvent.createByName.bind(_, null));
        }
            
        return {
            name: Reflect.hasField(obj, "name")? Reflect.field(obj, "name"):AbilityUtils.retrieveImplicitName(id),
            element: element,
            rawDesc: Reflect.field(obj, "description"),
            flags: flags,
            triggers: triggers
        };
    }
}