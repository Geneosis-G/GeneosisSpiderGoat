class VenomGoat extends GGMutator
	config(Geneosis);

var SkeletalMesh mRippedGoatMesh;
var Material mDevilMaterial;
var config bool isVenomUnlocked;
var array<GGPawn> mVenomPawns;

/**
 * if the mutator should be selectable in the Custom Game Menu.
 */
static function bool IsUnlocked( optional out array<AchievementDetails> out_CachedAchievements )
{
	//Function not called on custom mutators for now so this is not working
	return default.isVenomUnlocked;
}

/**
 * Unlock the mutator
 */
static function UnlockVenomGoat()
{
	if(!default.isVenomUnlocked)
	{
		PostJuice( "Unlocked Venom Goat" );
		default.isVenomUnlocked=true;
		static.StaticSaveConfig();
	}
}

static function bool IsVenomGoat(GGPawn gpawn)
{
	return gpawn != none && gpawn.mesh.SkeletalMesh == default.mRippedGoatMesh && gpawn.mesh.GetMaterial(0) == default.mDevilMaterial;
}

function bool IsVenomPawn(GGPawn gpawn)
{
	return mVenomPawns.Find(gpawn) != INDEX_NONE;
}

function AddVenomPawn(GGPawn gpawn)
{
	if(mVenomPawns.Find(gpawn) == INDEX_NONE)
	{
		mVenomPawns.AddItem(gpawn);
	}
}

function bool IsGoat(GGPawn gpawn)
{
	return gpawn.Mesh.SkeletalMesh == class'GGGoat'.default.mesh.SkeletalMesh;
}

function static PostJuice( string text )
{
	local GGGameInfo GGGI;
	local GGPlayerControllerGame GGPCG;
	local GGHUD localHUD;

	GGGI = GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game );
	GGPCG = GGPlayerControllerGame( GGGI.GetALocalPlayerController() );

	localHUD = GGHUD( GGPCG.myHUD );

	if( localHUD != none && localHUD.mHUDMovie != none )
	{
		localHUD.mHUDMovie.AddJuice( text );
	}
}

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;

	goat = GGGoat( other );

	if( goat != none )
	{
		if( IsValidForPlayer( goat ) )
		{
			if(!default.isVenomUnlocked)
			{
				DisplayLockMessage();
			}
			else
			{
				MakeVenomGoat(goat);
			}
		}
	}

	super.ModifyPlayer( other );
}

/**
 * Called when an actor takes damage
 */
function OnTakeDamage( Actor damagedActor, Actor damageCauser, int damage, class< DamageType > dmgType, vector momentum )
{
	super.OnTakeDamage(damagedActor, damageCauser, damage, dmgType, momentum);

	if(GGPawn(damagedActor) != none
	&& GGPawn(damagedActor).mIsRagdoll
	&& IsVenomPawn(GGPawn(damageCauser))
	&& class< GGDamageTypeAbility >(dmgType) != none)
	{
		MakeVenomGoat(GGPawn(damagedActor));
	}
}

function MakeVenomGoat(GGPawn gpawn)
{
	local int i;

	if(gpawn == none)
		return;

	if(gpawn.mesh.PhysicsAsset == class'GGGoat'.default.mesh.PhysicsAsset) gpawn.mesh.SetSkeletalMesh( mRippedGoatMesh );
	for(i=0 ; i<gpawn.mesh.GetNumElements() ; i++)
	{
		gpawn.mesh.SetMaterial( i, mDevilMaterial );
	}
	if(GGGoat(gpawn) != none) GGGoat(gpawn).mCanRagdollByVelocityOrImpact=false;
	if(GGNpc(gpawn) != none && gpawn.Controller == none)
	{
		GGNpc(gpawn).StandUp();
		gpawn.SpawnDefaultController();
	}
	AddVenomPawn(gpawn);
}

function DisplayLockMessage()
{
	ClearTimer(NameOf(DisplayLockMessage));
	WorldInfo.Game.Broadcast(self, "Venom Goat Locked :( Find the Venom easter egg to unlock it.");
	SetTimer(3.f, false, NameOf(DisplayLockMessage));
}

DefaultProperties
{
	mRippedGoatMesh=SkeletalMesh'goat.mesh.GoatRipped'
	mDevilMaterial=Material'goat.Materials.Goat_Mat_02'
}