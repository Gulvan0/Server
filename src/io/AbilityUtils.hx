package io;

import hxassert.Assert;
import ID.AbilityID;
import managers.AbilityManager;

class AbilityUtils
{
    public static function getElementAbbreviation(el:Element):String
    {
        return switch el {
            case Physical: "Ph";
            case Shadow: "Sh";
            case Lightning: "Lg";
            case Terra: "Tr";
            case Poison: "Po";
            case Fire: "Fi";
            case Frost: "Fr";
        }
    }

    public static function getElementByAbbreviation(abb:String):Null<Element>
    {
        return switch abb {
            case "Ph": Physical;
            case "Sh": Shadow;
            case "Lg": Lightning;
            case "Tr": Terra;
            case "Po": Poison;
            case "Fi": Fire;
            case "Fr": Frost;
            default: null;
        }
    }

    public static function retrieveImplicitName(ab:EnumValue):String
    {
        var contracted:String = ab.getName().substr(2);
        var full:String = "";
        for (i in 0...contracted.length)
        {
            var char:String = contracted.charAt(i);
            if (char.toUpperCase() == char && i > 0)
                full += " ";
            full += char;
        }
        return full;
    }

    public static function convertIntVariant(variant:Dynamic, length:Int):Array<Int>
    {
        if (Std.is(variant, Int))
            return extend([variant], length);
        else 
            return variant;
    }

    public static function extend<T>(a:Array<T>, newLength:Int):Array<T>
    {
        Assert.require(a.length > 0);
        var last:T = a[a.length-1];
        while (a.length < newLength)
            a.push(last);
        return a;
    }
    
    public static function isBH(ab:AbilityID):Bool 
    {
        return AbilityManager.abilities.get(ab).danmakuType != null;
    }

    public static function isEmpty(id:AbilityID):Bool 
    {
        return id == AbilityID.EmptyAbility || id == AbilityID.LockAbility;
    }
}