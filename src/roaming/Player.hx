package roaming;

import battle.Unit.ParameterList;
import sys.io.File;
import battle.struct.Pool;
import haxe.ds.IntMap;
import hxassert.Assert;
import roaming.enums.Attribute;
using MathUtils;

class TreeAbility
{
	public var id:ID;
	public var level:Int;
	public var maxlevel:Int;
	public var requirements:Array<Int>;

	public function new(){}
}

/**
 * Mimics an interactive roaming unit. Incapsulates work with XML savefiles
 * @author Gulvan
 */
class Player
{
	public var login(default, null):String;
	public var id(get, never):ID;
	public var name(get, set):String;

	public var level(get, never):Int;
	public var xp(get, never):Pool;
    public var rating(get, set):Int;

	public var element(get, set):Element;
	public var wheel(get, never):Array<ID>;
	public var attribs(get, set):Map<Attribute, Int>;

	public var abilityPoints(get, set):Int;
	public var attributePoints(get, set):Int;
	
	public var tree(get, never):Array<Array<TreeAbility>>;

	public var currentZone(get, set):Zone;

	public function new(login:String)
	{
		this.login = login;
	}

	public function get_id():ID
	{
		return ID.Player(login);
	}

	public function get_name():String
    {
		return getField("player/name");
	}

	public function set_name(newName:String):String
	{
		if (!newName.length.inRange(2, 18))
			return name;
		
		setField("name", newName);
		return newName;
	}

	//================================================================================================================

	public function get_rating():Int
    {
        return Std.parseInt(getField("rating"));
    }

    public function set_rating(v:Int):Int
    {
        setField("rating", "" + v);
        return v;
    }

	public function get_level():Int
    {
        return Std.parseInt(getField("player/level"));
    }

	public function get_xp():Pool
    {
        return new Pool(Std.parseInt(getField("player/xp")), GameRules.xpToLvlup(level));
    }

	public function gainXP(count:Int)
	{
		var xpPool:Pool = xp;
		while (xpPool.maxValue - xpPool.value <= count)
		{
			count -= xpPool.maxValue - xpPool.value;
			xpPool.value = 0;
			setField("level", "" + (level + 1));
			lvlupReward();
		}
		setField("xp", "" + (xpPool.value + count));
	}

	private function lvlupReward()
	{
		abilityPoints += GameRules.abPointsLvlupBonus();
		attributePoints += GameRules.attPointsLvlupBonus();
		attribs = Utils.sumMaps(attribs, GameRules.attributeLvlupBonus(element));
	}

	//==================================================================================================================

	public function get_element():Element
    {
		return Element.createByName(getField("player/element"));
	}

	public function set_element(newEl:Element):Element
	{
		setField("element", newEl.getName());
		return newEl;
	}

	public function get_wheel():Array<ID>
	{
		var wheel:Array<ID> = [];
		for (p in Main.playerData(login).elementsNamed("player"))
			for (w in p.elementsNamed("wheel"))
			{
				for (a in w.elementsNamed("ability"))
					wheel.push(ID.createByName(a.firstChild().nodeValue));
				break;
			}
		return wheel;
	}

	public function getWheelLength():Int
	{
		var sum:Int = 0;
		for (p in Main.playerData(login).elementsNamed("player"))
			for (w in p.elementsNamed("wheel"))
			{
				for (a in w.elementsNamed("ability"))
					if (a.firstChild().nodeValue != "EmptyAbility")
						sum++;
				break;
			}
		return sum;
	}

	public function addToWheel(ability:ID):Bool
	{
		if (getWheelLength() >= GameRules.wheelSlotCount(level))
			return false;
		
		var path:String = Main.playersDir() + login + ".xml";
        var s:String = File.getContent(path);
       	var ereg:EReg = ~/<ability>EmptyAbility<\/ability>/;
        s = ereg.replace(s, "<ability>" + ability.getName() + "</ability>");
        File.saveContent(path, s);
		return true;
	}

	public function removeFromWheel(ability:ID)
	{
		var path:String = Main.playersDir() + login + ".xml";
        var s:String = File.getContent(path);
       	var ereg:EReg = new EReg("<ability>" + ability.getName() + "</ability>", "");
        s = ereg.replace(s, "<ability>EmptyAbility</ability>");
        File.saveContent(path, s);
	}

	public function clearWheel()
	{
		var path:String = Main.playersDir() + login + ".xml";
        var s:String = File.getContent(path);
       	var ereg:EReg = ~/<ability>(?!EmptyAbility<\/ability>).+?<\/ability>/;
		while (ereg.match(s))
        	s = ereg.replace(s, "<ability>EmptyAbility</ability>");
        File.saveContent(path, s);
	}

	public function get_attribs():Map<Attribute, Int>
	{
		return [Attribute.Strength => Std.parseInt(getField("player/st")),
		Attribute.Flow => Std.parseInt(getField("player/fl")),
		Attribute.Intellect => Std.parseInt(getField("player/in"))];
	}

	private function set_attribs(v:Map<Attribute, Int>):Map<Attribute, Int>
	{
		setField("st", "" + v[Attribute.Strength]);
		setField("fl", "" + v[Attribute.Flow]);
		setField("in", "" + v[Attribute.Intellect]);
		return v;
	}

	public function incrementAtt(a:Attribute):Bool
	{
		if (attributePoints == 0)
			return false;
			
		attribs = [for (k in attribs.keys()) k => attribs[k] + (a == k? 1 : 0)];
		attributePoints--;
		return true;
	}

	//================================================================================================================

	private function get_abilityPoints():Int
	{
		return Std.parseInt(getField("player/abp"));
	}

	private function get_attributePoints():Int
	{
		return Std.parseInt(getField("player/attp"));
	}
	
	private function set_abilityPoints(v:Int):Int
	{
		setField("abp", "" + v);
		return v;
	}

	private function set_attributePoints(v:Int):Int
	{
		setField("attp", "" + v);
		return v;
	}

	//================================================================================================================

	public function get_tree():Array<Array<TreeAbility>>
	{
		var array:Array<Array<TreeAbility>> = [for (i in 0...GameRules.treeHeight) [for (i in 0...GameRules.treeWidth) new TreeAbility()]];

		for (e in Main.playerData(login).elementsNamed("tree"))
            for (r in e.elementsNamed("row"))
				for (a in r.elementsNamed("ability"))
					array[Std.parseInt(r.get("num"))][Std.parseInt(a.get("column"))].level = Std.parseInt(a.firstChild().nodeValue);

		for (r in getTreeInfo(element).elementsNamed("row"))
			for (a in r.elementsNamed("ability"))
			{
				array[Std.parseInt(r.get("num"))][Std.parseInt(a.get("column"))].maxlevel = Std.parseInt(a.get("maxlvl"));
				array[Std.parseInt(r.get("num"))][Std.parseInt(a.get("column"))].requirements = resolveRequirements(a.get("requires"));
				array[Std.parseInt(r.get("num"))][Std.parseInt(a.get("column"))].id = ID.createByName(a.firstChild().nodeValue);
			}

		return array;
	}
	
	public function learnAbility(i:Int, j:Int):Bool
	{
		Assert.assert(i.inRange(0, GameRules.treeHeight - 1));
		Assert.assert(j.inRange(0, GameRules.treeWidth - 1));
		
		for (deltaJ in getAbilityRequirements(i, j))
			if (getAbilityLvl(i - 1, j + deltaJ) == 0)
				return false;

		if (getAbilityLvl(i, j) == getAbilityMaxlvl(i, j))
			return false;

		if (abilityPoints == 0)
			return false;

		abilityPoints--;
		var path:String = Main.playersDir() + login + ".xml";
        var s:String = File.getContent(path);
        var ereg:EReg = new EReg("(<row num=\"" + i + "\">[\\s\\S]+?<ability column=\"" + j + "\">)(.+?)(</ability>)", "");
		ereg.match(s);
        s = ereg.replace(s, "$1" + (Std.parseInt(ereg.matched(2)) + 1) + "$3");
        File.saveContent(path, s);
		return true; 
	}

	public function resetTree()
	{
		var path:String = Main.playersDir() + login + ".xml";
        var s:String = File.getContent(path);
        var ereg:EReg = ~/(<row num=".">[\s\S]+?<ability column=".">)([1-9]+?)(<\/ability>)/;
		while (ereg.match(s))
        	s = ereg.replace(s, "$10$3");
        File.saveContent(path, s); 
	}

	private function getAbilityLvl(i:Int, j:Int):Int
	{
		Assert.assert(i.inRange(0, GameRules.treeHeight - 1));
		Assert.assert(j.inRange(0, GameRules.treeWidth - 1));

		for (e in Main.playerData(login).elementsNamed("tree"))
            for (r in e.elementsNamed("row"))
                if (Std.parseInt(r.get("num")) == i)
					for (a in r.elementsNamed("ability"))
						if (Std.parseInt(a.get("column")) == j)
							return Std.parseInt((a.firstChild().nodeValue));
		throw 'Error during a search for "lvl" field, coords: ($i, $j)';
	}

	private function getAbilityMaxlvl(i:Int, j:Int):Int
	{
		Assert.assert(i.inRange(0, GameRules.treeHeight - 1));
		Assert.assert(j.inRange(0, GameRules.treeWidth - 1));

		for (r in getTreeInfo(element).elementsNamed("row"))
			if (Std.parseInt(r.get("num")) == i)
				for (a in r.elementsNamed("ability"))
					if (Std.parseInt(a.get("column")) == j)
						return Std.parseInt(a.get("maxlvl"));
		throw 'Error during a search for "maxlvl" field, coords: ($i, $j)';
	}

	private function getAbilityRequirements(i:Int, j:Int):Array<Int>
	{
		Assert.assert(i.inRange(0, GameRules.treeHeight - 1));
		Assert.assert(j.inRange(0, GameRules.treeWidth - 1));
		var reqAr:Array<Int> = [];

		for (r in getTreeInfo(element).elementsNamed("row"))
			if (Std.parseInt(r.get("num")) == i)
				for (a in r.elementsNamed("ability"))
					if (Std.parseInt(a.get("column")) == j)
						return resolveRequirements(a.get("requires"));
		throw 'Error during a search for "requirements" field, coords: ($i, $j)';
	}

	private function getTreeInfo(element:Element):Xml
	{
		return Xml.parse(File.getContent(Main.gamedataDir() + element.getName() + "Tree.xml"));
	}

	private function resolveRequirements(s:String):Array<Int>
	{
		var a:Array<Int> = [];
		if (s.charAt(0) == '1')
			a.push(-1);
		if (s.charAt(1) == '1')
			a.push(0);
		if (s.charAt(2) == '1')
			a.push(1);
		return a;
	}

	//================================================================================================================

	public function reSpec()
	{
		var bonus = GameRules.attributeLvlupBonus(element);
		attribs = [for (k in bonus.keys()) k => 10 + bonus[k] * (level-1)];
		
		resetTree();
		clearWheel();
		
		abilityPoints = GameRules.initialAbilityPoints + GameRules.abPointsLvlupBonus() * (level-1);
		attributePoints = GameRules.initialAttributePoints + GameRules.attPointsLvlupBonus() * (level-1);
	}

	//================================================================================================================

	public function get_currentZone():Zone
    {
		return Zone.createByName(getField("progress/currentZone"));
	}

	public function set_currentZone(destination:Zone):Zone
	{
		setField("currentZone", destination.getName());
		return destination;
	}
    
	public function canVisit(zone:Zone):Bool
    {
        for (e in Main.playerData(login).elementsNamed("progress"))
            for (z in e.elementsNamed("zone"))
			{
				var zi:Zone = Zone.createByName(z.get("id"));
                if (zi == zone || (WorldMap.hasRoad(zi, zone) && getCompletedStageCount(zi) == WorldMap.stageCount(zi)))
                    return true;
			}
        return false;
    }

	public function getCompletedStageCount(zone:Zone):Int
	{
		for (e in Main.playerData(login).elementsNamed("progress"))
            for (z in e.elementsNamed("zone"))
                if (z.get("id") == zone.getName())
                    return Std.parseInt(z.firstChild().nodeValue);
		return 0;
	}

	public function proceed()
	{
		var path:String = Main.playersDir() + login + ".xml";
        var s:String = File.getContent(path);
        var ereg:EReg = new EReg('(<zone id="' + currentZone.getName() + '">)(.+?)(</zone>)', "");
        s = ereg.replace(s, "$1" + (Std.parseInt(ereg.matched(2)) + 1) + "$3");
        File.saveContent(path, s);
	}

	public function isAtBossStage():Bool
	{
		return getCompletedStageCount(currentZone) == WorldMap.stageCount(currentZone) - 1;
	}

	//================================================================================================================

	public function toParams():ParameterList
	{
		return {
		name: name,
		element: element,
		strength: attribs[Attribute.Strength],
		flow: attribs[Attribute.Flow],
		intellect: attribs[Attribute.Intellect],
		wheel: wheel,
		hp:  GameRules.basicHP + GameRules.hpStBonus(attribs[Attribute.Strength]),
		mana: GameRules.basicMana
		};
	}

	//================================================================================================================
	
	private function getField(path:String):String
	{
		var apath:Array<String> = path.split("/");
		var cur:Xml = Main.playerData(login);

		for (el in apath)
		{
			for (e in cur.elementsNamed(el))
			{
				cur = e;
				break;
			}
		}
		return cur.firstChild().nodeValue;
	}

	///Note that you state the field's name, not the path to the field; Element with this name should be unique 
	private function setField(name:String, newVal:String)
	{
		var path:String = Main.playersDir() + login + ".xml";
        var s:String = File.getContent(path);
        var ereg:EReg = new EReg("(<" + name + ">).+?(</" + name + ">)", "");
        s = ereg.replace(s, "$1" + newVal + "$2");
        File.saveContent(path, s);
	}
	
}