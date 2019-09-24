class StatsScoreboard extends Mutator;

function Timer()  //timer
{
	if(Level.Game.IsInState('MatchOver'))
	{
		SpamStatsScoreboardEntries();
		SpamWeaponStats();

		SetTimer(0.0,false);
	}
}

function SpamWeaponStats()
{
	local Controller C;
	local array<KFSSPlayerReplicationInfo.SSWeaponStatsArray> wsa;
	local int i,maxIndex,secIndex,trdIndex;
	local int max, sec, trd;
	max=0;sec=0;trd=0;
	for ( C = Level.ControllerList; C != none; C = C.NextController )
    {
        if (C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.Team != none )
        {
			wsa=KFSSPlayerReplicationInfo(C.playerReplicationinfo).SSWeaponStats;
			for(i=0;i<wsa.length;i++)
			{
				//find top three highest dam weapon record
				//then display
				if(wsa[i].dam>max)
				{
					maxIndex=i;
					max=wsa[i].dam;
				}
				else if(wsa[i].dam>sec&&wsa[i].dam<max)
				{
					secIndex=i;
					sec=wsa[i].dam;
				}
				else if(wsa[i].dam>trd&&wsa[i].dam<sec)
				{
					trdIndex=i;
					trd=wsa[i].dam;
				}
			}
			if(wsa.length!=0)
				PlayerController(C).ClientMessage("Weapon 1st "$wsa[maxIndex].weaponItemName$" Damage: "$wsa[maxIndex].dam$" Large Zeds Kills: "$wsa[maxIndex].largeKills);
			if(wsa.length>=2)
				PlayerController(C).ClientMessage("Weapon 2nd "$wsa[secIndex].weaponItemName$" Damage: "$wsa[secIndex].dam$" Large Zeds Kills: "$wsa[secIndex].largeKills);
			if(wsa.length>=3)
				PlayerController(C).ClientMessage("Weapon 3rd "$wsa[trdIndex].weaponItemName$" Damage: "$wsa[trdIndex].dam$" Large Zeds Kills: "$wsa[trdIndex].largeKills);
		}
    }
}

function SpamStatsScoreboardEntries()
{
	local Controller C;
	local KFSSPlayerReplicationInfo pri,maxhealingpri,maxkillspri,maxasspri,maxdmgpri,maxlargepri,maxdoshpri,maxhspri;

	maxhealingpri=KFSSPlayerReplicationInfo(Level.ControllerList.PlayerReplicationInfo);
	maxkillspri=maxhealingpri;
	maxasspri = maxhealingpri;
	maxdmgpri=maxhealingpri;
	maxlargepri = maxhealingpri;
	maxdoshpri = maxhealingpri;
	maxhspri = maxhealingpri;
	for ( C = Level.ControllerList; C != none; C = C.NextController )
    {
        if ( C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.Team != none )
        {
			pri=KFSSPlayerReplicationInfo(C.PlayerReplicationInfo);
			if(maxhealingpri.healing<=pri.healing)
			{
				maxhealingpri=pri;
			}
			if(maxkillspri.Kills<=pri.Kills)
			{
				maxkillspri=pri;
			}
			if(maxasspri.KillAssists<=pri.KillAssists)
			{
				maxasspri=pri;
			}
			if(maxdmgpri.dam<=pri.dam)
			{
				maxdmgpri=pri;
			}
			if(maxlargepri.fpKills+maxlargepri.scKills<=
			pri.fpKills+pri.scKills)
			{
				maxlargepri=pri;
			}
			if(maxdoshpri.moneyEarned<=pri.moneyEarned)
			{
				maxdoshpri=pri;
			}
			if(maxhspri.hs<=pri.hs)
			{
				maxhspri=pri;
			}
        }
    }
	BroadcastMessage("HealingMaster"$" : "$ maxhealingpri.PlayerName $" "$string(maxhealingpri.healing));
	BroadcastMessage("ZedsButcher"$" : "$ maxkillspri.PlayerName $" "$string(maxkillspri.Kills));
	BroadcastMessage("Assistant"$" : "$ maxasspri.PlayerName $" "$string(maxasspri.KillAssists));
	BroadcastMessage("Destroyer"$" : "$ maxdmgpri.PlayerName $" "$string(maxdmgpri.dam));
	BroadcastMessage("GiantKiller"$" : "$ maxlargepri.PlayerName $" "$string(maxlargepri.fpKills+maxlargepri.scKills));
	BroadcastMessage("MoneyBag"$" : "$ maxdoshpri.PlayerName $" "$string(maxdoshpri.moneyEarned));
	BroadcastMessage("SkullCracker"$" : "$ maxhspri.PlayerName $" "$string(maxhspri.hs));
}

function BroadcastMessage(string Msg)
{
  	local Controller P;
  	local PlayerController Player;

  	for ( P = Level.ControllerList; P != none; P = P.nextController ) 
  	{
    	Player = PlayerController(P);
    	if ( Player != none ) 
    	{
       		Player.ClientMessage(Msg);
     	}
  	}
}

event PreBeginPlay()
{
	if ( !MutatorIsAllowed() )
		Destroy();
	else if (bAddToServerPackages)
		AddToPackageMap();
}

function PostBeginPlay()  //Init
{
	local GameRules GR;
	local KFGameType gameType;
	Super.PostBeginPlay();
	GR = spawn(class'StatsScoreboardGameRules');
	StatsScoreboardGameRules(GR).ParentMutator = Self;
	if (Level.Game.GameRulesModifiers == None)
		Level.Game.GameRulesModifiers = GR;
	else Level.Game.GameRulesModifiers.AddGameRules(GR);

	Level.Game.ScoreBoardType = "StatsScoreboard.ScoreBoard";
	Level.Game.DefaultPlayerClassName = "StatsScoreboard.KFSSHumanPawn";
	gameType= KFGameType(Level.Game);
	gameType.PlayerControllerClassName="StatsScoreboard.KFSSPlayerController";
	gameType.PlayerControllerClass=Class'StatsScoreboard.KFSSPlayerController';
	if (Level.NetMode != NM_Standalone) 
	{
        AddToPackageMap();
        if (gameType.PlayerControllerClass != class'KFSSPlayerController') 
		{
            AddToPackageMap(string(gameType.PlayerControllerClass.Outer.name));
        }
    }

	SetTimer(1.0, True);
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if( PlayerController(Other) != none )
    {
        PlayerController(Other).PlayerReplicationInfoClass = Class'KFSSPlayerReplicationInfo';
    }
	return true;
}

defaultproperties
{
	GroupName="KFStatsScoreboard"
	FriendlyName="Stats Scoreboard"
	Description="Record everyone's contribution,same as KF2"
}