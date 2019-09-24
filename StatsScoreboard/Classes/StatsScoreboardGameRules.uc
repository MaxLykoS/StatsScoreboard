class StatsScoreboardGameRules extends GameRules;

var StatsScoreboard ParentMutator;

struct MonsterInfo 
{
    var KFMonster Monster;

    // variables below are set after NetDamage() call
	var bool bHeadshot;
    var int HeadHealth; // track head health to check headshots
    var bool bWasDecapitated; // was the monster decapitated before last damage? If bWasDecapitated=true then bHeadshot=false
};
var array<MonsterInfo> MonsterInfos;
var private transient KFMonster LastSeachedMonster; //used to optimize GetMonsterIndex()
var private transient int       LastFoundMonsterIndex;

function PostBeginPlay()
{
    MonsterInfos.Length = KFGameType(Level.Game).MaxMonsters; //reserve a space that will be required anyway
    SetTimer(1.0, True);
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

function Timer()  //Timer check wave begin
{
	if(KFGameType(Level.Game).bWaveBossInProgress||KFGameType(Level.Game).bWaveInProgress)
	{
        OnWaveBegin();
        SetTimer(0.0,false);
	}

    if(Level.Game.IsInState('Match Over'))
    {
        OnWaveEnd();
    }
}

//creates a new record, if monster not found
function int GetMonsterIndex(KFMonster Monster)
{
    local int i, count, free_index;

    if ( LastSeachedMonster == Monster )
        return LastFoundMonsterIndex;

    count = MonsterInfos.length;
    free_index = count;
    LastSeachedMonster = Monster;
    for ( i = 0; i < count; ++i ) {
        if ( MonsterInfos[i].Monster == Monster ) {
            LastFoundMonsterIndex = i;
            return i;
        }
        if ( free_index == count && MonsterInfos[i].Monster == none )
            free_index = i;
    }
    // if reached here - no monster is found, so init a first free record
    if ( free_index >= MonsterInfos.length ) {
        // if free_index out of bounds, maybe MaxZombiesOnce is changed during the game
        if ( MonsterInfos.length < KFGameType(Level.Game).MaxMonsters )
            MonsterInfos.insert(free_index, KFGameType(Level.Game).MaxMonsters - MonsterInfos.length);
        // MaxZombiesOnce was ok, just added extra monsters
        if ( free_index >= MonsterInfos.length )
            MonsterInfos.insert(free_index, 1);
    }
    ClearMonsterInfo(free_index);
    MonsterInfos[free_index].Monster = Monster;
    //MonsterInfos[free_index].HeadHealth = Monster.HeadHealth * Monster.DifficultyHeadHealthModifer() * Monster.NumPlayersHeadHealthModifer();
    MonsterInfos[free_index].HeadHealth = Monster.HeadHealth;
    LastFoundMonsterIndex = free_index;
    return free_index;
}

function ClearMonsterInfo(int index)
{
    MonsterInfos[index].Monster = none;
    MonsterInfos[index].HeadHealth = 0;
    MonsterInfos[index].bWasDecapitated = false;
}

function int CalculateZedsVal(KFMonster zed)
{
	local KFGameType KFGT;
	local float Dif,KillScore;
	KFGT=KFGameType(Level.Game);
	Dif=KFGT.GameDifficulty;
	KillScore=zed.ScoringValue;

	if ( Dif >= 5.0 ) // Suicidal and Hell on Earth
    {
        KillScore *= 0.65;
    }
    else if ( Dif >= 4.0 ) // Hard
    {
        KillScore *= 0.85;
    }
    else if ( Dif >= 2.0 ) // Normal
    {
        KillScore *= 1.0;
    }
    else //if ( Dif == 1.0 ) // Beginner
    {
        KillScore *= 2.0;
    }
    // Increase score in a short game, so the player can afford to buy cool stuff by the end
    if( KFGT.KFGameLength == 0 )
    {
        KillScore *= 1.75;
    }
    return KillScore;
}

function AddDoshPerPlayerOnWaveEnd()
{
	local Controller C;
    local int moneyPerPlayer,div,Score;
    local TeamInfo T;

    for ( C = Level.ControllerList; C != none; C = C.NextController )
    {
        if ( C.Pawn != none && C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.Team != none )
        {
            T = C.PlayerReplicationInfo.Team;
            div++;
        }
    }

    if ( T == none || T.Score <= 0 )
    {
        return;
    }
    Score=T.Score;
    moneyPerPlayer = int(T.Score / float(div));

    for ( C = Level.ControllerList; C != none; C = C.NextController )
    {
        if ( C.Pawn != none && C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.Team != none )
        {
            if ( div == 1 )
            {
                KFSSPlayerReplicationInfo(C.PlayerReplicationInfo).moneyEarned+=Score;
                Score = 0;
            }
            else
            {
                KFSSPlayerReplicationInfo(C.PlayerReplicationInfo).moneyEarned+=moneyPerPlayer;
                Score-=moneyPerPlayer;
                div--;
            }

            if( Score <= 0 )
            {
                Score = 0;
                Break;
            }
        }
    }
}

function ResetStatsPerWave()
{
    local Controller C;
    local KFSSPlayerReplicationInfo sspri;
    for ( C = Level.ControllerList; C != none; C = C.nextController ) 
  	{
        sspri=KFSSPlayerReplicationInfo(C.PlayerReplicationInfo);
        sspri.timeAlivePerWave=0;
        sspri.hsPerWave=0;
        sspri.bsPerWave=0;
        sspri.bulletPerWave=0;
        sspri.killsPerWave=0;
        KFSSHumanPawn(C.Pawn).timeRespawn=Level.GRI.ElapsedTime;
  	}
}

function SpawnAccuraryText()
{
    local Controller C;
    local PlayerController pc;
    local KFSSPlayerReplicationInfo sspri;
    for ( C = Level.ControllerList; C != none; C = C.nextController ) 
  	{
        sspri=KFSSPlayerReplicationInfo(C.PlayerReplicationInfo);
        pc=PlayerController(C);
        pc.clientmessage("WaveAccuracy "$string(float(sspri.hsPerWave)/float(sspri.bulletPerWave))$" "$
        "WaveHSAccuracy "$string(float(sspri.hsPerWave)/float((sspri.hsPerWave+sspri.bsPerWave)))$" "$
        "KillSpeed "$string(float(sspri.killsPerWave)/float(sspri.timeAlivePerWave))$" per sec");
        //pc.clientmessage(sspri.timeAlivePerWave$" Seconds in this wave");
        if(Level.Game.IsInState('MatchOver'))
        {
            pc.clientmessage("TotalAccuracy "$string(float(sspri.hs/sspri.bullet))$" "$
            "TotalHSAccuracy "$string(float(sspri.hs/(sspri.hs+sspri.bs)))$" "$
            "ToTalKillSpeed "$string(float(sspri.kills/sspri.timeAlivePerGame))$" per sec");
            //pc.clientmessage(sspri.timeAlivePerGame$" Seconds in total");
        }
  	}
}

function UpdateSSTimeAlive()
{
    local Controller C;
    local KFSSPlayerReplicationInfo sspri;
    local KFSSHumanPawn kfsshp;
    for ( C = Level.ControllerList; C != none; C = C.nextController ) 
  	{
        sspri=KFSSPlayerReplicationInfo(C.PlayerReplicationInfo);
        kfsshp = KFSSHumanPawn(C.Pawn);
        sspri.timeAlivePerWave+=Level.GRI.ElapsedTime-kfsshp.timeRespawn;
        sspri.timeAlivePerGame+=sspri.timeAlivePerWave;
  	}
}

function OnWaveEnd()
{
    UpdateSSTimeAlive();
    AddDoshPerPlayerOnWaveEnd();
    SpawnAccuraryText();
    SetTimer(1.0,true);
}

function OnWaveBegin()
{
    ResetStatsPerWave();
}

//kill callback
//Broadcast kill message 
function ScoreKill(Controller Killer,Controller Killed)
{
	
	//local int i;
	local KFMonster monster;
	local PlayerController pc;
	local PlayerReplicationInfo PRI;
	local KFSSPlayerReplicationInfo SSPRI;

	if(KFMonsterController(Killed)!=none)
	{
		if(KFGameType(Level.Game).NumMonsters<=0&&KFGameType(Level.Game).TotalMaxMonsters<=0)
			OnWaveEnd();
	}

    Super.ScoreKill(Killer, Killed);


    if(Killer!=None && Killed!=None)
    {
    	if ( Killer.bIsPlayer)
     	{
     		pc=PlayerController(Killer);
			PRI=pc.PlayerReplicationInfo;
			SSPRI = KFSSPlayerReplicationInfo(PRI);
     		monster=KFMonster(Killed.Pawn);
     		if(monster!= None)
     		{
     			//pc.ClientMessage("Earn "$string(CalculateZedsVal(monster)));
                SSPRI.moneyEarned+=CalculateZedsVal(monster);
                SSPRI.killsPerWave++;
     			if(ZombieFleshPound(monster)!=None)
     			{
     				//pc.ClientMessage("Kill 1 fp");
					if(SSPRI!=None)
                    {
						SSPRI.fpKills++;
                        SSPRI.SSUpdateWeaponStats(Killer.Pawn.Weapon.ItemName,0,1);
                    }		 	
     			}
				else if(ZombieScrake(monster)!=None)
     			{
     				//pc.ClientMessage("Kill 1 sc");
     				if(SSPRI!=None)
                    {
						SSPRI.scKills++;
                        SSPRI.SSUpdateWeaponStats(Killer.Pawn.Weapon.ItemName,0,1);
                    }
     			}
				else if(ZombieHusk(monster)!=None)
     			{
     				//pc.ClientMessage("Kill 1 husk");
     				if(SSPRI!=None)
						SSPRI.huskKills++;
     			}
				else if(ZombieSiren(monster)!=None)
     			{
     				//pc.ClientMessage("Kill 1 siren");
     				if(SSPRI!=None)
						SSPRI.sirenKills++;
     			}
      	  	}
    	}
	}
}

//Dmg callback
function int NetDamage(int OriginalDamage,int Damage,pawn injured,pawn instigatedBy,vector HitLocation,out vector Momentum,class<DamageType> DamageType)
{
	local int RealDamage,idx;
	local KFHumanPawn Player;
	local KFMonster ZedVictim;
	local class<KFWeaponDamageType> KFDamType;
	local bool bP2M;

	local PlayerController PC;
	local KFSSPlayerReplicationInfo SSPRI;

	KFDamType = class<KFWeaponDamageType>(DamageType);
	Player = KFHumanPawn(instigatedBy);//get attacker
	ZedVictim = KFMonster(injured);    //get attacked

	if ( Damage == 0 )
		return 0;

	Damage = super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
	if(Damage>injured.Health)
		RealDamage=injured.Health;
	else
		RealDamage=Damage;
    //get real dmg

	bP2M = ZedVictim != none && KFDamType != none && instigatedBy != none && PlayerController(instigatedBy.Controller) != none;
	if ( bP2M ) 
	{
		if(Player != None && RealDamage > 0  && ParentMutator != None)
		{
			idx = GetMonsterIndex(ZedVictim);
        	MonsterInfos[idx].bHeadshot = !MonsterInfos[idx].bWasDecapitated && KFDamType.default.bCheckForHeadShots
            && (ZedVictim.bDecapitated || int(ZedVictim.HeadHealth) < MonsterInfos[idx].HeadHealth);

			PC = PlayerController(Player.Controller);

			SSPRI = KFSSPlayerReplicationInfo(PC.PlayerReplicationInfo);
            SSPRI.dam+=RealDamage;
            SSPRI.SSUpdateWeaponStats(instigatedBy.Weapon.ItemName,RealDamage,0);

        	if ( MonsterInfos[idx].bHeadshot )
			{
                SSPRI.hs++;
                SSPRI.hsPerWave++;
				//PC.ClientMessage("Headshot");
        	}
			else if ( !ZedVictim.bDecapitated ) 
        	{
            	if ( KFDamType.default.bCheckForHeadShots )
                {
                    SSPRI.bs++;
                    SSPRI.bsPerWave++;
                    //PC.ClientMessage("Bodyshot");
                }
        	}
		}
    }
	if ( bP2M )
	{
        MonsterInfos[idx].HeadHealth = ZedVictim.HeadHealth;
        MonsterInfos[idx].bWasDecapitated = ZedVictim.bDecapitated;
    }
	return Damage;
}