class SSKFPlayerReplicationInfo extends KFPlayerReplicationInfo;

struct SSWeaponStatsArray
{
    var string weaponItemName;
    var int dam;
    var int largeKills;
};

var int fpKills,scKills,huskKills,sirenKills;
var int healing,dam,moneyEarned,hs,bs,bullet;
var int timeAlivePerGame,timeAlivePerWave,hsPerWave,bsPerWave,bulletPerWave,killsPerWave;
var array<SSWeaponStatsArray> SSWeaponStats;

replication
{
	reliable if ( bNetDirty && (Role == Role_Authority) )
        fpKills,scKills,huskKills,sirenKills,healing,dam,moneyEarned,hs,bs,bullet,
        timeAlivePerGame,timeAlivePerWave,hsPerWave,bsPerWave,bulletPerWave,killsPerWave,
        SSWeaponStats;
}

function ReceiveRewardForHealing( int MedicReward, KFPawn Healee )
{
    // only give reward if healee is not Ringmaster
    if( !Healee.IsA('KF_RingMasterNPC') )
    {
        Score += MedicReward;
    	ThreeSecondScore += MedicReward;
    	Team.Score += MedicReward;

        //record healing score
        healing+=MedicReward;
    }
}

function SSUpdateWeaponStats(string itemName,int _dam,int _largeKills)
{
    local int i;
    for(i=0;i<SSWeaponStats.length;i++)
    {
        if(itemName==SSWeaponStats[i].weaponItemName)
        {
            SSWeaponStats[0].dam += _dam;
            SSWeaponStats[0].largeKills += _largeKills;
        }
    }
    if(i==SSWeaponStats.length)
    {
        SSWeaponStats.Insert(0,1);
        SSWeaponStats[0].weaponItemName = itemName;
        SSWeaponStats[0].dam = _dam;
        SSWeaponStats[0].largeKills = _largeKills;
    }
}