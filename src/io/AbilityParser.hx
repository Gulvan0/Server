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

enum AbilityFlag
{
    AOE;
    Multistrike(count:Int);
    Ultimate;
}

//Name and description are not parsed on server
typedef AbilityProperites =
{
    var id:AbilityID;
    var element:Element;
    var type:AbilityType;
    var maxlvl:Int;
    var flags:Array<AbilityFlag>;
}

typedef ActiveProperties =
{
    var target:AbilityTarget;
    var manacost:Array<Int>;
    var cooldown:Array<Int>;
    var danmaku:Bool;
}

typedef DanmakuProperties =
{
    var danmakuType:AttackType; 
    var danmakuDispenser:DispenserType; 
}

typedef PassiveProperties =
{
    var triggers:Array<BattleEvent>; 
}

typedef AuraProperties =
{
    var affectedTeams:Array<RelativeTeam>;
    var affectsSummons:Bool;
    var element:Element;
}

class AbilityParser 
{

    public static var abilities(default, null):Map<AbilityID, AbilityProperties> = [];
    public static var actives(default, null):Map<AbilityID, ActiveProperties> = [];
    public static var passives(default, null):Map<AbilityID, PassiveProperties> = [];
    public static var auras(default, null):Map<AbilityID, AuraProperties> = [];
    public static var danmaku(default, null):Map<AbilityID, DanmakuProperties> = [];

    public function initMaps()
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
                switch abilities.get(id).type
                {
                    case Passive:
                        initPassive(abilityObject, id);
                    case Aura:
                        initAura(abilityObject, id, element);
                    default:
                        initActive(abilityObject, id, abilities.get(id).maxlvl);
                }
            }
        }

        var aurasPath = Main.gamedataDir + "Summon\\auras.json";
        var auraList = Json.parse(File.getContent(aurasPath));
        for (aura in Reflect.fields(auraList))
            initAura(Reflect.field(auraList, aura), AbilityID.createByName(aura));
    }

    private function initAbility(obj:Dynamic, id:AbilityID, element:Element)
    {
        Assert.assert(obj.hasField("type"));
        Assert.assert(obj.hasField("maxlvl"));

        var type:AbilityType = AbilityType.createByName(obj.field("type"));
        var maxlvl:Int = obj.field("maxlvl");

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
        
        abilities.set(id, {
            id:id,
            element: element,
            type: type,
            maxlvl: maxlvl,
            flags: flags
        });

        if (type == Summon)
            SummonManager.initSummon(obj);
    }

    private function initActive(obj:Dynamic, id:AbilityID, maxlvl:Int)
    {
        Assert.assert(Reflect.hasField(obj, "target"));
        Assert.assert(Reflect.hasField(obj, "manacost"));
        Assert.assert(Reflect.hasField(obj, "cooldown"));

        var manacost:Array<Int> = AbilityUtils.convertIntVariant(Reflect.field(obj, "manacost"), maxlvl);
        var cooldown:Array<Int> = AbilityUtils.convertIntVariant(Reflect.field(obj, "cooldown"), maxlvl);
        var target:AbilityTarget = AbilityTarget.createByName(Reflect.field(obj, "target"));
        var danmaku:Bool = Reflect.hasField(obj, "danmakuProps");

        actives.set(id, {target: target, cooldown: cooldown, manacost: manacost, danmaku: danmaku});
        if (danmaku)
            initDanmaku(Reflect.field(obj, "danmakuProps"), id);
    }

    private function initPassive(obj:Dynamic, id:AbilityID)
    {
        var triggersStr:Array<String> = [];
        if (Reflect.hasField(obj, "triggers"))
            triggersStr = Reflect.field(obj, "triggers");

        passives.set(id, {triggers: triggersStr.map(BattleEvent.createByName.bind(_, null))});
    }
    
    private function initAura(obj:Dynamic, id:AbilityID, ?element:Element)
    {
        Assert.assert(Reflect.hasField(props, "affects"));
        Assert.assert(Reflect.hasField(props, "summonsAffected"));

        var affectedStr:Array<String> = Reflect.field(props, "affects");
        var summonsAffected:Bool = Reflect.field(props, "summonsAffected");
        var el:Element;
        if (element != null)
            el = element;
        else 
            el = Reflect.field(props, "element");

        auras.set(id, {affectedTeams: affectedStr.map(RelativeTeam.createByName.bind(_, null)), affectsSummons: summonsAffected, element: el});
    }

    private function initDanmaku(props:Dynamic, id:AbilityID)
    {
        Assert.assert(Reflect.hasField(props, "type"));
        Assert.assert(Reflect.hasField(props, "dispenser"));

        var danmakuType = AttackType.createByName(Reflect.field(props, "type"));
        var danmakuDispenser = DispenserType.createByName(Reflect.field(props, "dispenser"));

        danmaku.set(id, {danmakuType: danmakuType, danmakuDispenser: danmakuDispenser});
    }
}