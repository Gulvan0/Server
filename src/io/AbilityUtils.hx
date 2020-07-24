package io;

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

    public static function retrieveImplicitName(ab:AbilityID):String
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
    
    public static function isBH(ab:AbilityID):Bool 
    {
        return AbilityManager.abilities.get(ab).danmakuType != null;
    }
}