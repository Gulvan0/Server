package;
import haxe.crypto.Md5;
import roaming.Player;
import roaming.Unit.RoamUnitParameters;
import roaming.enums.Attribute;
import sys.FileSystem;
import sys.io.File;
using StringTools;

/**
 * Utilities for working with savefile
 * @author Gulvan
 */
class SaveLoad 
{

	public var xml:Null<Xml>;
	private static var playerFields:Array<String> = ["name", "element", "xp", "level", "abp", "attp", "st", "fl", "in"];
	
	public function new()
	{
		
	}
	
	public function open(fileName:String)
	{
		var path:String = exefolder() + "\\" + fileName;
		
		if (!FileSystem.exists(path))
			throw "File not found: " + path;
		
		xml = Xml.parse(File.getContent(path));
	}
	
	public function close()
	{
		xml = null;
	}
	
	public function save(progress:Progress, player:Player, ?fileName:String = "savefile.xml")
	{
		xml = Xml.createDocument();
		xml.addChild(createProgressNode(progress));
		xml.addChild(createPlayerNode(player));
		File.saveContent(exefolder() + "\\" + fileName, XMLUtils.print(xml));
		xml = null;
	}
	
	private static function createProgressNode(progress:Progress):Xml
	{
		var prog:Xml = Xml.createElement("progress");
		var keys:Array<Zone> = [for (key in progress.progress.keys()) key];
		keys.sort(function(a, b) return Reflect.compare(a.getName().toLowerCase(), b.getName().toLowerCase()));
		for (key in keys)
		{
			var el:Xml = Xml.createElement("zone");
			el.set("id", key.getName());
			el.addChild(Xml.createPCData("" + progress.progress[key].value));
			prog.addChild(el);
		}
		var curr:Xml = Xml.createElement("current");
		curr.addChild(Xml.createPCData(progress.currentZone.getName()));
		prog.addChild(curr);
		
		return prog;
	}
	
	private static function createPlayerNode(player:Player):Xml
	{
		var pl:Xml = Xml.createElement("player");
		var elements:Map<String, String> = [
			"name"=>player.name,
			"element"=>player.element.getName(),
			"xp"=>"" + player.xp.value,
			"level"=>"" + player.level,
			"abp"=>"" + player.abilityPoints,
			"attp"=>"" + player.attributePoints,
			"st"=>"" + player.attribs[Attribute.Strength],
			"fl"=>"" + player.attribs[Attribute.Flow],
			"in"=>"" + player.attribs[Attribute.Intellect]
		];
		
		for (key in playerFields)
		{
			var el:Xml = Xml.createElement(key);
			el.addChild(Xml.createPCData(elements[key]));
			pl.addChild(el);
		}
		
		return pl;
	}
	
	private static function exefolder():String
	{
		var exepath:String = Sys.programPath();
		return exepath.substring(0, exepath.lastIndexOf("\\"));
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
	
}