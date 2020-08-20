package managers;
using StringTools;
using Lambda;

class CommandManager 
{
    public static final commandArgs:Map<String, Int> = [
    "help" => 0,
    "printbattle" => 1, 
    "lvlup" => 2
    ];

    public static function processLine(line:String)
    {
        switch line.split(' ')
        {
            case ["help"]:
                help();
            case ["printbattle", player]:
                printBattle(player);
            case ["lvlup", player, Std.parseInt(_) => amount]:
                gainLevels(player, amount);
            case seq if (commandArgs.exists(seq[0])):
                Sys.println('Incorrect number of arguments, expected ${commandArgs.get(seq[0])}');
            case seq:
                Sys.println('Unknown command: ${seq[0]}');
        }

        processLine(Sys.stdin().readLine());
    }

    private static function help()
    {
        Sys.println("Available commands: ");
        for (cmd in commandArgs.keys())
            Sys.println('- $cmd');
    }

    private static function printBattle(login:String)
    {
        var model = BattleManager.instance.getModel(login);
        if (model == null)
            Sys.println('$login is not in battle');
        else
            Sys.println(model.toString());
    }

	private static function gainLevels(login:String, amount:Int) 
	{
        new PlayerdataManager();
		PlayerdataManager.instance.loadPlayer(login);
		for (i in 0...amount)
			PlayerdataManager.instance.gainXP(GameRules.xpToLvlup(i+1), login);
	}
}