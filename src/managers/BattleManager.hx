package managers;

import ID.UnitID;
import GameRules.BattleOutcome;
import battle.Model;
import battle.enums.Team;
import battle.Unit;
import mphx.connection.IConnection;
import battle.IInteractiveModel;

class BattleManager 
{
    private static var models:Map<String, IInteractiveModel> = new Map(); // login -> Model
	private static var rooms:Map<String, BattleRoom> = new Map(); // login -> Room
	private static var openRooms:Array<String> = [];

    public function getModel(l:String) 
    {
        return models.get(l);
    }

    public function getRoom(l:String) 
    {
        return rooms.get(l);
    }

    public function isFighting(player:String):Bool
    {
        return models.exists(player);
    }
    
    public function removePlayer(login:String) 
    {
		if (isFighting(login))
		{
			rooms[login].clients.remove(login);
			models[login].quit(login);
			models.remove(login);
		}
				
		rooms.remove(login);
		openRooms.remove(login);
    }

    public function findMatch(peer:String)
	{
		if (Lambda.empty(openRooms))
		{
			var room:BattleRoom = new BattleRoom();
			room.add(peer); //Allowing to access from it by login
			rooms[peer] = room; //Creating a link
			openRooms.push(peer); //Hey, I'm lfg
		}
		else
		{
			var enemy:String = openRooms.splice(0, 1)[0];
			rooms[enemy].add(peer);
			rooms[peer] = rooms[enemy];
			var p1:Unit = loadUnit(enemy, Team.Left, 0);
			var p2:Unit = loadUnit(peer, Team.Right, 0);
			models[enemy] = new Model([p1], [p2], rooms[peer], terminate);
			models[peer] = models[enemy];
			
			for (l in rooms[peer].clients)
			{
				var c:IConnection = LoginManager.instance.getConnection(l);
				var d:String = models[peer].getBattleData(l);
				c.send("BattleStarted", d);
			}
		}
    }
    
    public static function terminate(winners:Array<String>, losers:Array<String>, ?draw:Bool = false)
	{
		var winnerPlayers = winners.map(PlayerdataManager.instance.cache.get);
		var loserPlayers = losers.map(PlayerdataManager.instance.cache.get);
		var pvp:Bool = !Lambda.empty(losers) && !Lambda.empty(winners);

		var deltaRating:Int = 0;
		for (player in winnerPlayers) 
			deltaRating += player.rating;
		for (player in loserPlayers) 
			deltaRating -= player.rating;
		deltaRating = Math.round(Math.abs(deltaRating));

		function terminatePlayer(login:String, outcome:BattleOutcome)
		{
			var xpReward = pvp? GameRules.xpRewardPVP(outcome) : GameRules.xpRewardPVE(outcome, false); //? Add boss stage check later
			var ratingReward = pvp? GameRules.ratingRewardPVP(outcome, deltaRating) : null;
			PlayerdataManager.instance.gainXP(xpReward, login);
			PlayerdataManager.instance.earnRating(ratingReward, login);

			var resultString:String = outcome.getName().toUpperCase();
			rooms.remove(login);
			models.remove(login);
			LoginManager.instance.getConnection(login).send("BattleEnded", {outcome: resultString, xp: xpReward, rating: ratingReward});
		}

		for (player in winners)
			terminatePlayer(player, draw? Draw : Win);
		for (player in losers)
			terminatePlayer(player, draw? Draw : Loss);
	}
	
	private function createEnemyArray(zone:Zone, stage:Int):Array<Unit>
	{
		var enemyIDs:Array<UnitID> = XMLUtils.parseStage(zone, stage);
		var enemies:Array<Unit> = [];
		for (i in 0...enemyIDs.length)
			enemies.push(new Unit(enemyIDs[i], Team.Right, i));
			
		return enemies;
	}
	
	private static function loadUnit(login:String, team:Team, pos:Int):Unit
	{
		var i:UnitID = UnitID.Player(login);
		var par:ParameterList = new Player(login).toParams();
		return new Unit(i, team, pos, par);
	}

    public function new() 
    {
        
    }
}