package io;

import managers.SummonManager;
import battle.data.Passives.BattleEvent;
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

enum AbilityFlag
{
    AOE;
    Multistrike(count:Int);
    Ultimate;
}

typedef Ability =
{
    var id:AbilityID;
    var name:String;
    var description:Map<String, String>;
    var element:Element;
    var type:AbilityType;
    var target:Null<AbilityTarget>;
    var manacost:Array<Int>; //Empty if passive
    var cooldown:Array<Int>;//Empty if passive
    var maxlvl:Int;
    var danmakuType:Null<AttackType>; //Null if not danmaku ability
    var danmakuDispenser:Null<DispenserType>; //Null if not danmaku ability
    var flags:Array<AbilityFlag>;
    var triggers:Array<BattleEvent>; //Empty if active
}

class AbilityParser 
{

    public static var abilities(default, null):Map<AbilityID, Ability> = [];

    public static function initMaps()
    {
        Assert.assert(Lambda.empty(abilities));
        for (element in Element.createAll())
        {
            var path = Main.gamedataDir + AbilityUtils.getElementAbbreviation(element) + "\\abilities.json";
            if (!FileSystem.exists(path))
                continue;

            var abList = Json.parse(File.getContent(path));
            for (ab in Reflect.fields(abList))
            {
                var id:AbilityID = AbilityID.createByName(ab);
                var abilityObject = Reflect.field(abList, ab);
                initAbility(abilityObject, id, element);
            }
        }

        var aurasPath = Main.gamedataDir + "Summon\\auras.json";
        var auraList = Json.parse(File.getContent(aurasPath));
        for (aura in Reflect.fields(auraList))
            initSummonAura(Reflect.field(auraList, aura), AbilityID.createByName(aura));
    }

    private static function initSummonAura(obj:Dynamic, id:AbilityID) 
    {
        Assert.assert(obj.hasField("element"));
        Assert.assert(obj.hasField("allies"));
        Assert.assert(obj.hasField("summons"));

        abilities.set(id, {
            id:id,
            name:"",
            description: [],
            element: obj.field("element"),
            type: Aura(obj.field("summons"), obj.field("allies")),
            target: null,
            cooldown: [],
            manacost: [],
            maxlvl: -1,
            danmakuType: null,
            danmakuDispenser: null,
            flags: [],
            triggers: []
        });
    }

    private static function initAbility(obj:Dynamic, id:AbilityID, element:Element)
    {
        Assert.assert(obj.hasField("description"));
        Assert.assert(obj.hasField("type"));
        Assert.assert(obj.hasField("maxlvl"));

        var name:String = obj.hasField("name")? obj.field("name") : AbilityUtils.retrieveImplicitName(id);
        var description:Map<String, String> = [];
        var descObj = obj.field("description");
        for (prop in Reflect.fields(descObj))
            description.set(prop, Reflect.field(descObj, prop));
        var target:Null<AbilityTarget> = obj.hasField("target")? AbilityTarget.createByName(obj.field("target")) : null;
        
        var type:AbilityType;
        var typeStr = obj.field("type");
        if (typeStr == "Aura")
        {
            Assert.assert(obj.hasField("allied"));
            Assert.assert(obj.hasField("summons"));
            type = Aura(obj.field("summons"), obj.field("allied"));
        }
        else
            type = AbilityType.createByName(typeStr);

        var maxlvl:Int = obj.field("maxlvl");
        var manacost:Array<Int> = [];
        if (obj.hasField("manacost"))
            manacost = AbilityUtils.convertIntVariant(obj.field("manacost"), maxlvl);
        var cooldown:Array<Int> = [];
        if (obj.hasField("cooldown"))
            manacost = AbilityUtils.convertIntVariant(obj.field("cooldown"), maxlvl);

        var danmakuType:Null<AttackType> = null;
        var danmakuDispenser:Null<DispenserType> = null;
        if (obj.hasField("danmakuProps"))
        {
            var props = obj.field("danmakuProps");
            Assert.assert(Reflect.hasField(props, "type"));
            Assert.assert(Reflect.hasField(props, "dispenser"));
            danmakuType = AttackType.createByName(Reflect.field(props, "type"));
            danmakuDispenser = DispenserType.createByName(Reflect.field(props, "dispenser"));
        }
        var flags:Array<AbilityFlag> = [];
        if (obj.hasField("flags"))
        {
            var flagStrs:Array<String> = obj.field("flags");
            for (flagStr in flagStrs)
                if (flagStr == "multistrike")
                {
                    Assert.assert(obj.hasField("strikeCount"));
                    flags.push(Multistrike(obj.field("strikeCount")));
                }
                else if (flagStr == "aoe")
                    flags.push(AOE);
                else if (flagStr == "ultimate")
                    flags.push(Ultimate);
        }
        var triggersStr:Array<String> = [];
        if (obj.hasField("triggers"))
            triggersStr = obj.field("triggers");

        abilities.set(id, {
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
            flags: flags,
            triggers: triggersStr.map(BattleEvent.createByName.bind(_, null))
        });

        if (type == Summon)
            SummonManager.initSummon(obj);
    }
}