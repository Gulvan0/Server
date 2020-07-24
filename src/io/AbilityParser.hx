package io;

import battle.enums.AttackType;
import battle.enums.DispenserType;
import hxassert.Assert;
import battle.enums.AbilityTarget;
import battle.enums.AbilityType;
import ID.AbilityID;
import sys.io.File;
import sys.FileSystem;
import haxe.Json;
using Reflect;

typedef Ability =
{
    var id:AbilityID;
    var name:String;
    var description:Map<String, String>;
    var element:Element;
    var type:AbilityType;
    var target:Null<AbilityTarget>;
    ///Empty if passive
    var manacost:Array<Int>; 
    ///Empty if passive
    var cooldown:Array<Int>;
    var maxlvl:Int;
    ///Null if not danmaku ability
    var danmakuType:Null<AttackType>; 
    ///Null if not danmaku ability
    var danmakuDispenser:Null<DispenserType>; 
    ///False if passive
    var aoe:Bool; 
}

class AbilityParser 
{
    public static function createMap():Map<AbilityID, Ability>
    {
        var abilities:Map<AbilityID, Ability> = [];
        for (element in Element.createAll())
        {
            var path = Main.gamedataDir + AbilityUtils.getElementAbbreviation(element) + "\\abilities.json";
            if (!FileSystem.exists(path))
                continue;

            var full = Json.parse(File.getContent(path));
            for (prop in Reflect.fields(full))
            {
                var id:AbilityID = AbilityID.createByName(prop);
                var abilityObject = full.field(prop);
                abilities.set(id, initAbility(abilityObject, id, element));
            }
        }
        return abilities;
    }

    private static function initAbility(obj:Dynamic, id:AbilityID, element:Element):Ability
    {
        Assert.assert(obj.hasField("description"));
        Assert.assert(obj.hasField("type"));
        Assert.assert(obj.hasField("maxlvl"));

        var name:String = obj.hasField("name")? obj.field("name") : AbilityUtils.retrieveImplicitName(id);
        var description:Map<String, String> = [];
        var descObj = obj.field("description");
        for (prop in Reflect.fields(descObj))
            description.set(prop, descObj.field(prop));
        var type:AbilityType = AbilityType.createByName("type");
        var target:Null<AbilityTarget> = obj.hasField("target")? AbilityTarget.createByName(obj.field("target")) : null;

        var maxlvl:Int = obj.field("maxlvl");
        var manacost:Array<Int>;
        if (!obj.hasField("manacost"))
            manacost = [];
        else
        {
            var value:Dynamic = obj.field("manacost");
            if (Std.is(value, Int))
                manacost = extend([value], maxlvl);
            else 
                manacost = value;
        }
        var cooldown:Array<Int>;
        if (!obj.hasField("cooldown"))
            cooldown = [];
        else
        {
            var value:Dynamic = obj.field("cooldown");
            if (Std.is(value, Int))
                cooldown = extend([value], maxlvl);
            else 
                cooldown = value;
        }

        var danmakuType:Null<AttackType> = null;
        var danmakuDispenser:Null<DispenserType> = null;
        if (obj.hasField("danmakuProps"))
        {
            var props = obj.field("danmakuProps");
            Assert.assert(props.hasField("type"));
            Assert.assert(props.hasField("dispenser"));
            danmakuType = props.field("type");
            danmakuDispenser = cast props.field("dispenser");
        }
        var aoe:Bool = false;
        if (obj.hasField("aoe"))
            aoe = obj.field("aoe");

        return {
            id:id,
            name:name,
            description: description,
            element: element,
            type: type,
            target: target,
            cooldown: cooldown,
            manacost: manacost,
            maxlvl: maxlvl,
            danmakuType: danmakuType,
            danmakuDispenser: danmakuDispenser,
            aoe: aoe
        };
    }

    private static function extend<T>(a:Array<T>, newLength:Int):Array<T>
    {
        Assert.require(a.length > 0);
        var last:T = a[a.length-1];
        while (a.length < newLength)
            a.push(last);
        return a;
    }
}