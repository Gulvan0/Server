package managers;

import ID.AbilityID;
import MathUtils.IntPoint;
import Main.Focus;
import battle.IInteractiveModel;
import mphx.connection.IConnection;
import mphx.server.impl.Server;

class ConnectionManager 
{
    public static var server:Server;
    public static var loginManager:LoginManager;
    public static var playerManager:PlayerdataManager;
    public static var battleManager:BattleManager;
    
    public static function init() 
	{
		#if local
		server = new Server("localhost", 5000);
		#else
		server = new Server("ec2-18-222-25-127.us-east-2.compute.amazonaws.com", 5000);
		#end
        loginManager = new LoginManager();
        playerManager = new PlayerdataManager();
        battleManager = new BattleManager();
        mapEvents();
    }

    public static function warn(login:String, message:String)
	{
		var c:IConnection = loginManager.getConnection(login);
		if (c != null)
			c.send("BattleWarning", message);
		trace(message);
	}

    private static function logOut(s:String, c:IConnection) 
    {
        var l:String = loginManager.getLogin(c);
		if (l != null)
		{
			battleManager.removePlayer(l);
			loginManager.logout(c);
		}
    }

    private static function asLogged(c:IConnection, func:String->Void)
    {
        var login = loginManager.getLogin(c);
        if (login == null)
            c.send("LoginNeeded");
        else 
            func(login);
    }

    private static function asFighting(requester:IConnection, func:String->Void)
	{
		var l:String = loginManager.getLogin(requester);
		if (l != null)
			if (battleManager.isFighting(l))
				func(l);
			else
				requester.send("NotInBattle");
		else
			requester.send("LoginNeeded");
    }
    
    private static function getFighting(requester:IConnection)
	{
		var l:String = loginManager.getLogin(requester);
		if (l != null)
			if (battleManager.isFighting(l))
				return l;
			else
				requester.send("NotInBattle");
		else
            requester.send("LoginNeeded");
        return null;
	}
    
    private static function mapEvents() 
	{
        server.onConnectionClose = logOut;
		server.events.on("Login", loginManager.login);
		server.events.on("Register", loginManager.registerAndLogin);

		server.events.on("GetVersion", function(data:Dynamic, sender:IConnection){
			sender.send("Version", Main.version);
		});

		server.events.on("GetPlPrData", function(data:Dynamic, sender:IConnection){
			if (loginManager.getLogin(sender) != null)
				loginManager.sendPlPrData(sender);
			else
				sender.send("LoginNeeded");
		});
		
		server.events.on("FindMatch", function(d, sender:IConnection){
			asLogged(sender, battleManager.findMatch);
		});

		//======================================================================================================
		// ROAM EVENTS
		//======================================================================================================

		server.events.on("LearnAbility", function(d:String, sender:IConnection){
            var data:Array<Int> = d.split("|").map(Std.parseInt);
            asLogged(sender, playerManager.learnAbility.bind(data[0], data[1]));
		});

		server.events.on("PutAbility", function(d:String, sender:IConnection){
			var l:Null<String> = loginManager.getLogin(sender);
            if (l != null)
            {
				var data:Array<String> = d.split("|");
				playerManager.putAbility(AbilityID.createByName(data[0]), Std.parseInt(data[1]), l);
            }
		});

		server.events.on("RemoveAbility", function(d:String, sender:IConnection){
			var l:Null<String> = loginManager.getLogin(sender);
			if (l != null)
				playerManager.removeFromWheel(Std.parseInt(d), l);
			else
				sender.send("LoginNeeded");
		});

		server.events.on("IncrementAttribute", function(d:String, sender:IConnection){
			var l:Null<String> = loginManager.getLogin(sender);
			if (l != null)
				playerManager.incrementAtt(Attribute.createByName(d), l);
			else
				sender.send("LoginNeeded");
		});

		server.events.on("ReSpec", function(d:Dynamic, sender:IConnection){
			var l:Null<String> = loginManager.getLogin(sender);
			if (l != null)
			{
				playerManager.reSpec(l);
				loginManager.sendPlPrData(sender);
			}
			else
				sender.send("LoginNeeded");
		});

		//======================================================================================================
		// BATTLE EVENTS
		//======================================================================================================
		
		server.events.on("UseRequest", function(focus:Focus, sender:IConnection){
			var l:Null<String> = getFighting(sender);
			if (l != null)
				battleManager.getModel(l).useRequest(l, focus.abilityNum, focus.target);
		});
		
		server.events.on("SkipTurn", function(data:Dynamic, sender:IConnection){
			var l:Null<String> = getFighting(sender);
			if (l != null)
				battleManager.getModel(l).skipTurn(l);
		});
		
		server.events.on("QuitBattle", function(data:Dynamic, sender:IConnection){
			var l:Null<String> = getFighting(sender);
			if (l != null)
				battleManager.getModel(l).quit(l);
		});

		server.events.on("BHTick", function(data:Dynamic, sender:IConnection){
			var l:Null<String> = getFighting(sender);
			if (l != null)
				battleManager.getRoom(l).share(l, "BHTick", data);
		});

		server.events.on("BHVanish", function(data:Dynamic, sender:IConnection){
			var l:Null<String> = getFighting(sender);
			if (l != null)
				battleManager.getRoom(l).share(l, "BHVanish", data);
		});

		server.events.on("BHBoom", function(data:Dynamic, sender:IConnection){
			var l:Null<String> = getFighting(sender);
			if (l != null)
				battleManager.getModel(l).boom(l);
		});

		server.events.on("BHFinished", function(data:Dynamic, sender:IConnection){
			var l:Null<String> = getFighting(sender);
			if (l != null)
			{
				var responsesAwaited:Int = battleManager.getRoom(l).clients.length - 1;
				server.events.on("DemoClosed", function (d:Dynamic, s:IConnection){
					responsesAwaited--;
					if (responsesAwaited == 0)
					{
						server.events.remove("DemoClosed");
						sender.send("BHCloseGame");
						battleManager.getModel(l).bhOver(l);
					}
				});
				battleManager.getRoom(l).share(l, "BHCloseDemo");
			}
		});

		//======================================================================================================
		// PATTERN EVENTS
		//======================================================================================================

		server.events.on("SetPattern", function(data:{id:String, pos:Int, pattern:String}, sender:IConnection){
			var l:Null<String> = loginManager.getLogin(sender);
			if (l != null)
				playerManager.setPattern(AbilityID.createByName(data.id), data.pos, data.pattern, l);
			else
				sender.send("LoginNeeded");
		});

		server.events.on("GetPattern", function(data:{id:String, pos:Int}, sender:IConnection){
			var l:Null<String> = loginManager.getLogin(sender);
			if (l != null)
				sender.send("BHPattern", playerManager.getPattern(AbilityID.createByName(data.id), data.pos, l));
			else
				sender.send("LoginNeeded");
		});

		//======================================================================================================
		
		server.start();
	}
}