package managers;

import ID.UnitID;
import GameRules.BattleOutcome;
import roaming.Player;
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
		var w:Array<Player> = [for (login in winners) new Player(login)];
		var l:Array<Player> = [for (login in losers) new Player(login)];
		var pvp:Bool = !Lambda.empty(losers) && !Lambda.empty(winners);
		var deltaRating:Int = 0;
		for (player in w) deltaRating += player.rating;
		for (player in l) deltaRating -= player.rating;
		deltaRating = Math.round(Math.abs(deltaRating));

		var xpRewards:Map<String, Int> = [];
		var ratingRewards:Map<String, Null<Int>> = [];
		for (player in w)
			if (pvp)
			{
				xpRewards[player.login] = GameRules.xpRewardPVP(draw? BattleOutcome.Draw : BattleOutcome.Win);
				ratingRewards[player.login] = GameRules.ratingRewardPVP(draw? BattleOutcome.Draw : BattleOutcome.Win, deltaRating);
				player.gainXP(xpRewards[player.login]);
				player.rating += ratingRewards[player.login];
			}
			else
			{
				xpRewards[player.login] = GameRules.xpRewardPVE(draw? BattleOutcome.Draw : BattleOutcome.Win, player.isAtBossStage());
				ratingRewards[player.login] = null;
				player.gainXP(xpRewards[player.login]);
			}
		for (player in l)
			if (pvp)
			{
				xpRewards[player.login] = GameRules.xpRewardPVP(draw? BattleOutcome.Draw : BattleOutcome.Loss);
				ratingRewards[player.login] = GameRules.ratingRewardPVP(draw? BattleOutcome.Draw : BattleOutcome.Loss, deltaRating);
				player.gainXP(xpRewards[player.login]);
				player.rating += ratingRewards[player.login];
			}
			else
			{
				xpRewards[player.login] = GameRules.xpRewardPVE(draw? BattleOutcome.Draw : BattleOutcome.Loss, player.isAtBossStage());
				ratingRewards[player.login] = null;
				player.gainXP(xpRewards[player.login]);
			}

		for (l in winners.concat(losers)) 
		{
			var resultString:String = draw? "DRAW" : Lambda.has(winners, l)? "WIN" : "LOSS";
			rooms.remove(l);
			models.remove(l);
			LoginManager.instance.getConnection(l).send("BattleEnded", {outcome: resultString, xp: xpRewards[l], rating: ratingRewards[l]});
		}
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