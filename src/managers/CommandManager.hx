package managers;
using StringTools;

class CommandManager 
{
    public static function processLine(line:String)
    {
        var parts = line.split(' ');
        var command = parts[0];
        var args = parts.slice(1);

        switch command
        {
            case "printbattle":
                printBattle(args);
            case "lvlup":
                gainLevels(args);
            default:
                Sys.println('Unknown command: $command');
        }

        processLine(Sys.stdin().readLine());
    }

    private static function printBattle(args:Array<String>)
    {
        var argsExpected:Int = 1;
        if (args.length != argsExpected)
        {
            Sys.println('Incorrect number of arguments, expected $argsExpected');
            return;
        }

        var login = args[0];
        var model = BattleManager.instance.getModel(login);
        if (model == null)
        {
            Sys.println('$login is not in battle');
            return;
        }

        Sys.println(model.toString());
    }

	private static function gainLevels(args:Array<String>) 
	{
        var argsExpected:Int = 2;
        if (args.length != argsExpected)
        {
            Sys.println('Incorrect number of arguments, expected $argsExpected');
            return;
        }

        var login = args[0];
        var amount = Std.parseInt(args[1]);
		new PlayerdataManager();
		PlayerdataManager.instance.loadPlayer(login);
		for (i in 0...amount)
			PlayerdataManager.instance.gainXP(GameRules.xpToLvlup(i+1), login);
	}
}