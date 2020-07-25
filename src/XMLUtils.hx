package;
import ID.AbilityID;
import ID.BuffID;
import ID.UnitID;
import MathUtils.Point;
import battle.Unit.ParameterList;
import battle.data.Passives.BattleEvent;
import haxe.CallStack;
import haxe.xml.Printer;
import roaming.Ability;
import sys.FileSystem;
import sys.io.File;
using StringTools;

/**
 * Provides static functions that parse various types of XML used in game
 * @author Gulvan
 */
class XMLUtils 
{
	
	public static function generate(values:Array<Map<String, String>>, typeNodeName:String):Xml
	{
		var xml:Xml = Xml.createDocument();
		for (m in values)
		{
			var node:Xml = Xml.createElement(typeNodeName);
			for (k in m.keys())
			{
				var el:Xml = Xml.createElement(k);
				el.addChild(Xml.createPCData(m[k]));
				node.addChild(el);
			}
			xml.addChild(node);
		}
		return xml;
	}
	
	public static function parseTree(element:Element):Array<Array<Ability>>
	{
		var xml:Xml = getTree(element);
		var abilityGrid:Array<Array<Ability>> = [];
		
		if (xml == null)
			return abilityGrid;
		
		for (row in xml.elementsNamed("row"))
		{
			var abilityRow:Array<Ability> = [];
			
			for (ability in row.elementsNamed("ability"))
			{
				var id:AbilityID = AbilityID.createByName(ability.get("id"));
				var maxlvl:Int = Std.parseInt(ability.get("maxlvl"));
				
				abilityRow.push(new Ability(id, maxlvl));
			}
			
			abilityGrid.push(abilityRow);
		}	
		
		return abilityGrid;
	}
	
	public static function parseTreePaths(element:Element):Array<Array<Array<Int>>>
	{
		var xml:Null<Xml> = getTree(element);
		var requirements:Array<Array<Array<Int>>> = [];
		
		if (xml == null)
			return requirements;
		
		for (row in xml.elementsNamed("row"))
		{
			var a:Array<Array<Int>> = [];
			for (ability in row.elementsNamed("ability"))
			{
				var reqStr:String = ability.get("requires");
				var reqAr:Array<Int> = [];
				
				if (reqStr.charAt(0) == '1')
					reqAr.push(-1);
				if (reqStr.charAt(1) == '1')
					reqAr.push(0);
				if (reqStr.charAt(2) == '1')
					reqAr.push(1);
				
				a.push(reqAr);
			}
			requirements.push(a);
		}
		
		return requirements;
	}
	
	public static function parseStage(zone:Zone, stage:Int):Array<UnitID>
	{
		var output:Array<UnitID> = [];
		var xml:Xml = fromFile("data\\Stages.xml");
		
		xml = findNode(xml, "zone", "id", zone.getName());
		xml = findNode(xml, "stage", "number", "" + stage);
		xml = xml.firstChild();
			
		for (enemyID in parseValueArray(xml))
			output.push(Type.createEnum(UnitID, enemyID));
		
		return output;
	}
	
	public static function nextZones(zone:Zone):Array<Zone>
	{
		var xml:Xml = fromFile("data\\Stages.xml");
		
		xml = findNode(xml, "zone", "id", zone.getName());
		xml = findNode(xml, "unlocks");
		xml = xml.firstChild();
			
		return [for (id in parseValueArray(xml)) castNode(id, Zone)];
	}
	
	public static function stageCount(zone:Zone):Int
	{
		var count:Int = 0;
		var xml:Xml = fromFile("data\\Stages.xml");
		
		xml = findNode(xml, "zone", "id", zone.getName());
		for (node in xml.elementsNamed("stage"))
			count++;
			
		return count;
	}
	
	public static function parseAbility<T>(ability:AbilityID, param:String, paramType:T):Dynamic
	{
		var xml:Xml = fromFile("data\\Abilities.xml");
		xml = findNode(xml, "ability", "id", ability.getName());
		xml = findNode(xml, param);
		xml = xml.firstChild();
		return castNode(xml.nodeValue, paramType);
	}

	public static function getParticleCount(bhAbility:AbilityID):Int
	{
		var xml:Xml = fromFile("data\\Abilities.xml");
		xml = findNode(xml, "ability", "id", bhAbility.getName());
		xml = findNode(xml, "bh");
		xml = findNode(xml, "count");
		return Std.parseInt(xml.firstChild().nodeValue);
	}

	public static function getBHParameters(ability:AbilityID):Xml
	{
		var xml:Xml = fromFile("data\\Abilities.xml");
		xml = findNode(xml, "ability", "id", ability.getName());
		xml = findNode(xml, "bh");
		return xml;
	}

	public static function getAbilityPosition(id:AbilityID, element:Element):Point
	{
		for (row in getTree(element).elementsNamed("row"))
			for (ability in row.elementsNamed("ability"))
				if (ability.get("id") == id.getName())
					return new Point(Std.parseInt(row.get("num")), Std.parseInt(ability.get("column")));
		return null;
	}
	
	public static function parseTriggers(object:EnumValue):Array<BattleEvent>
	{
		var output:Array<BattleEvent> = [];
		var xml:Xml;
		
		if (object.getName().substr(0, 4) == "Buff")
			xml = findNode(fromFile("data\\Buffs.xml"), "buff", "id", object.getName());
		else
			xml = findNode(fromFile("data\\Abilities.xml"), "ability", "id", object.getName());
		
		if (xml.elementsNamed("triggers").hasNext())
		{
			xml = findNode(xml, "triggers");
			xml = xml.firstChild();
			
			for (event in parseValueArray(xml))
				output.push(Type.createEnum(BattleEvent, event));
		}
		
		return output;
	}
	
	public static function parseBuff<T>(buff:BuffID, param:String, paramType:T):Dynamic
	{
		var xml:Xml = fromFile("data\\Buffs.xml");
		xml = findNode(xml, "buff", "id", buff.getName());
		xml = findNode(xml, param);
		xml = xml.firstChild();
			
		return castNode(xml.nodeValue, paramType);
	}
	public static function print(xml:Xml):String
	{
		var s:String = Printer.print(xml, true);
		var line:Null<String> = null;
		
		var i:Int = 0;
		for (j in 0...s.length)
		{
			if (i >= s.length)
				break;
			if (s.charAt(i) == "\n")
				if (line == null)
					line = "";
				else
				{
					var newline:String = strip(line);
					i -= line.length - newline.length + 1;
					s = s.replace("\n" + line + "\n", newline);
					line = null;
				}
			else if (line != null)
				if (s.charAt(i) == "<")
					line = null;
				else
					line += s.charAt(i);
			i++;
		}
		while (s.indexOf("\t</") != -1)
			s = s.replace("\t</", "</");
		return s;
	}
	
	private static function strip(s:String):String
	{
		var j:Int = 0;
		for (i in 0...s.length)
		{
			if (j >= s.length)
				break;
			if (s.isSpace(j))
				s = s.substr(0, j) + s.substr(j + 1);
			else
				j++;
		}
		return s;
	}
	
	//================================================================================
    // PRIVATE
    //================================================================================	
	
	private static function getTree(element:Element):Null<Xml>
	{
		switch (element)
		{
			case Element.Lightning:
				return fromFile("data\\LightningTree.xml");
			default:
				return null;
		}
	}
	
	private static function castNode<T>(value:Dynamic, type:T):Dynamic
	{
		if (Std.is(type, String))
			return value;
		else if (Std.is(type, Int))
			return Std.parseInt(value);
		else if (Std.is(type, Bool))
			return value == "true";
		else if (Std.is(type, Float))
			return Std.parseFloat(value);
		else if (Std.is(type, Enum))
			return Type.createEnum(cast type, value);
			
		throw "Node casting error: Unknown node type: " + type;
	}
	
	private static function findNode(xml:Xml, nodeName:String, ?keyAtt:String = "", ?keyAttValue:String = ""):Xml
	{
		for (node in xml.elementsNamed(nodeName))
			if (keyAtt == "" || node.get(keyAtt) == keyAttValue)
				return node;
			
		if (keyAtt == "")
			throw "Node not found: " + nodeName;
		else
			throw "Node not found: " + nodeName + " with key attribute " + keyAtt + " = " + keyAttValue;
	}
	
	private static function parseValueArray(node:Xml):Array<String>
	{
		var output:Array<String> = [];
		var stream:String = "";
		
		for (i in 0...node.nodeValue.length)
		{
			var char:String = node.nodeValue.charAt(i);
			if (char != " ")
				if (char != ",")
					stream += char;
				else
				{
					output.push(stream);
					stream = "";
				}
		}
		
		if (stream != "")
			output.push(stream);
		
		return output;
	}
	
	private static function fromFile(path:String):Xml
	{
		var dirpath:String = Sys.programPath();
		dirpath = dirpath.substring(0, dirpath.lastIndexOf("\\"));

		return Xml.parse(File.getContent(dirpath + "\\" + path));
	}
	
}