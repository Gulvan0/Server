package managers;

import io.AbilityUtils;
import hxassert.Assert;
import ID.SummonID;

typedef ParsedSummon = {
    var id:SummonID;
    var name:String;
    var maxhp:Array<Int>;
}

class SummonManager 
{
    public static var summons(default, null):Map<SummonID, ParsedSummon> = [];

    public static function initSummon(abObj:Dynamic) 
    {
        Assert.assert(Reflect.hasField(abObj, "summon"));
        Assert.assert(Reflect.hasField(abObj, "maxlvl"));
        Assert.assert(Reflect.hasField(abObj, "maxhp"));

        var id:SummonID = Reflect.field(abObj, "summon");
        summons.set(id, {
            id: id,
            name: Reflect.hasField(abObj, "name")? Reflect.field(abObj, "name"):AbilityUtils.retrieveImplicitName(id),
            maxhp: AbilityUtils.convertIntVariant(Reflect.field(abObj, "maxhp"), Reflect.field(abObj, "maxlvl"))
        });
    }
}