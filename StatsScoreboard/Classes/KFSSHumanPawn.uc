class KFSSHumanPawn extends KFHumanPawn;
var int timeRespawn;
var StatsScoreboard ssmut;

function PostBeginPlay()
{
    super.PostBeginPlay();

    timeRespawn = Level.GRI.ElapsedTime;
}

//KFPC.bAltFire != 0
//KFPC.bFire != 0
function DeactivateSpawnProtection()
{
    local KFWeapon kfw;
    local Class<BaseProjectileFire> projFireClass;
    local KFSSPlayerReplicationInfo sspri;
    local int m,projCount;
	super.DeactivateSpawnProtection();
    if(KFPC.bFire != 0)
        m=0;
    else if(KFPC.bAltFire != 0)
        m=1;

    kfw = KFWeapon(Weapon);
    sspri = KFSSPlayerReplicationInfo(OwnerPRI);

    projFireClass=class<BaseProjectileFire>(kfw.FireModeClass[m]);
    //KFPC.ClientMessage("FireMod "$string(m));
    if(Syringe(kfw)!=None||Welder(kfw)!=None)
    {
        //do nothing
    }
    else if(projFireClass == None)
    {
        sspri.bullet+=1;
        sspri.bulletPerWave++;
        //KFPC.ClientMessage("1 bullet");
    }
    else if(projFireClass!=None)
    {
        if(class<KFWeaponDamageType>(projFireClass.default.ProjectileClass.default.MyDamageType).default.bCheckForHeadShots)
        {
            projCount = projFireClass.default.ProjPerFire*Min(projFireClass.default.AmmoPerFire,kfw.MagAmmoRemaining);
            sspri.bullet+=projCount;
            sspri.bulletPerWave+=projCount;

            //KFPC.ClientMessage(string(projCount)$" bullet");
        }
    }        
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    local KFSSPlayerReplicationInfo sspri;
    super.Died(Killer,damageType,HitLocation);
    sspri=KFSSPlayerReplicationInfo(OwnerPRI);

    sspri.timeAlivePerWave+=Level.GRI.ElapsedTime-timeRespawn;
    sspri.timeAlivePerGame+=sspri.timeAlivePerWave;
}