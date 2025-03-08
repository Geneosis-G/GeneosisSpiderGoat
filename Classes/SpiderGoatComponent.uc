class SpiderGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;
var StaticMeshComponent spiderBodyMesh;
var SkeletalMeshComponent spiderLegsMesh1;
var SkeletalMeshComponent spiderLegsMesh2;
var SkeletalMeshComponent spiderLegsMesh3;
var SkeletalMeshComponent spiderLegsMesh4;
var array<StaticMeshComponent> spiderFootMesh;

var bool isForwardPressed;
var bool isBackPressed;
var bool isSpiderWalkActive;
var bool checkVenomUnlock;

var EPhysics oldPhysics;
var vector oldVelocity;
var rotator oldDeltaRot;
var vector lastFloor;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	local array<name> attachedSockets;
	local int i;
	local StaticMeshComponent sfm;

	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		spiderBodyMesh.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( spiderBodyMesh, 'hairSocket' );
		spiderLegsMesh1.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( spiderLegsMesh1, 'hairSocket' );
		spiderLegsMesh2.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( spiderLegsMesh2, 'hairSocket' );
		spiderLegsMesh3.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( spiderLegsMesh3, 'hairSocket' );
		spiderLegsMesh4.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( spiderLegsMesh4, 'hairSocket' );

		FindSocketsToAttachTo(gMe.mesh, attachedSockets);

		for( i = 0; i < attachedSockets.Length; i++ )
		{
			sfm = new( self ) class'StaticMeshComponent';
			sfm.SetStaticMesh(StaticMesh'GasStation.Mesh.GasStation_Bottle_07');
			sfm.SetScale(0.6f);
			sfm.SetScale3D(vect(1.f, 1.f, 0.4f));
			spiderFootMesh.AddItem( sfm );
			sfm.SetLightEnvironment( gMe.mesh.LightEnvironment );
			gMe.mesh.AttachComponentToSocket( sfm, attachedSockets[i] );
		}

		/*gMe.bCrawler=true;
		gMe.bRollToDesired=true;
		gMe.Floor=vect(0, 0, 1);*/

		gMe.SetTimer( 1.f, false, NameOf( AllowVenom ), self);
		gMe.SetTimer( 1.f, false, NameOf( SetSpiderWalk ), self);
	}
}

function SetSpiderWalk()
{
	gMe.WalkingPhysics = PHYS_Spider;
	gMe.bRollToDesired = true;
	gMe.mCanWallWalk = true;
	gMe.mCanWallRun = true;
	gMe.mWallRunSpeed = gMe.mStrafeSpeed;
	gMe.mWallRunZ = 0;
	gMe.mWallRunBoostZ = 0;
	gMe.mSpiderRunOffLedgeSpeed = gMe.mWalkSpeed + ( gMe.mSprintSpeed - gMe.mWalkSpeed ) * 0.1f;
	gMe.mAllowedGroundImpactUpDot = 0.6f;
}

function AllowVenom()
{
	if(!class'VenomGoat'.static.IsVenomGoat(gMe))
	{
		checkVenomUnlock=true;
	}
}

function FindSocketsToAttachTo( SkeletalMeshComponent mesh, out array<name> out_sockets )
{
	local SkeletalMeshSocket socket;
	local int i;

	i = 0;
	do
	{
		socket = mesh.GetSocketByName( name("SkateSocket_" $ i++) );
		if( socket != none )
		{
			out_sockets.AddItem( socket.SocketName );
		}
	}
	until( socket == none );
}

function Tick( float deltaTime )
{
	if(checkVenomUnlock)
	{
		if(class'VenomGoat'.static.IsVenomGoat(gMe))
		{
			class'VenomGoat'.static.UnlockVenomGoat();
			gMe.mCanRagdollByVelocityOrImpact=false;
			checkVenomUnlock=false;
		}
	}

	if( gMe.Physics == PHYS_WallRun )
	{
		//@todo Usha, fixme!
		gMe.SetPhysics( PHYS_Spider );
	}

	/// OLD SPIDER PHYSICS ///
	/*if(isSpiderWalkActive)
	{
		if(gMe.Physics == PHYS_Walking || gMe.Physics == PHYS_WallRun)
		{
			//myMut.WorldInfo.Game.Broadcast(myMut, "Physics forced to spider");
			gMe.SetPhysics(PHYS_Spider);
		}
	}

	if(gMe.Physics == PHYS_Spider)
	{
		UpdateSpiderRotation(deltaTime);
	}

	oldPhysics=gMe.Physics;
	oldVelocity=gMe.Velocity;
	lastFloor=gMe.Floor;*/
}

/**
 * Updates the leaning while wall running.
 */
function UpdateSpiderRotation(float deltaTime)/// OLD SPIDER PHYSICS ///
{
	local rotator NewRot, deltaRot;
	local Vector X, Y, Z, Va, Vb, Vn;
	local float speed, rotationSpeed;
	local float sina, cosa, angle, currentBaseY;

	//myMut.WorldInfo.Game.Broadcast(myMut, "Floor=" $ gMe.Floor);

	//Correct rotation
	deltaRot=oldDeltaRot;
	NewRot = Rotator(gMe.Floor);
	NewRot.Pitch -= 16384; // aligns the pawns feet to the surface

	if(gMe.Floor != lastFloor)
	{
		Va=Normal(vector(NewRot));
		Vb=QuatRotateVector(QuatFindBetween(lastFloor, gMe.Floor), Normal(vector(gMe.Rotation)));
		Vn=Normal(gMe.Floor);

		sina = VSize(Va cross Vb);
		cosa = Va dot Vb;
		angle = atan2( sina, cosa );
		if(Vn dot ( Va cross Vb ) < 0)
		{
			angle=-angle;
		}
		deltaRot.Yaw=RadToUnrRot * angle;
	}

	rotationSpeed=gMe.Controller!=none?GGPlayerControllerGame( gMe.Controller ).mRotationRate.Yaw:0;
	deltaRot.Yaw+=rotationSpeed/2 * deltaTime;
	deltaRot.Yaw=deltaRot.Yaw%65536;

	GetAxes(NewRot, X, Y, Z);
	NewRot = QuatToRotator( QuatProduct(
	QuatFromAxisAndAngle(Z, UnrRotToRad * deltaRot.Yaw),
	QuatFromRotator(NewRot)
	) );

	//myMut.WorldInfo.Game.Broadcast(myMut, "NewRot=" $ NewRot);

	gMe.SetRotation(NewRot);

	oldDeltaRot=deltaRot;

	//Correct velocity angle
	if(gMe.mIsSprinting)
	{
		speed=gMe.mSprintSpeed;
	}
	else
	{
		speed=gMe.mWalkSpeed;
	}

	if(gMe.Controller != none)
	{
		if(GGLocalPlayer(PlayerController( gMe.Controller ).Player).mIsUsingGamePad)
		{
			currentBaseY=PlayerController( gMe.Controller ).PlayerInput.aBaseY;
			if(currentBaseY > 0.5)
			{
				gMe.Velocity=Normal(vector(gMe.Rotation))*speed;
			}
			else if(currentBaseY < -0.5)
			{
				gMe.Velocity=Normal(vector(gMe.Rotation))*-speed;
			}
		}
		else
		{
			if(isForwardPressed)
			{
				gMe.Velocity=Normal(vector(gMe.Rotation))*speed;
			}
			else if(isBackPressed)
			{
				gMe.Velocity=Normal(vector(gMe.Rotation))*-speed;
			}
		}
	}
}

/// OLD SPIDER PHYSICS ///
/*function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;
	local int i;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if( localInput.IsKeyIsPressed( "GBA_Jump", string( newKey ) ) )
		{
			gMe.Floor=vect(0, 0, 1);
		}

		if( localInput.IsKeyIsPressed( "GBA_Forward", string( newKey ) ) )
		{
			isForwardPressed=true;
		}

		if( localInput.IsKeyIsPressed( "GBA_Back", string( newKey ) ) )
		{
			isBackPressed=true;
		}

		if( localInput.IsKeyIsPressed( "GBA_Baa", string( newKey ) ) && gMe.mGrapplingHook.IsGrappling())
		{
			isSpiderWalkActive=!isSpiderWalkActive;

			if(!isSpiderWalkActive && gMe.Physics == PHYS_Spider)
			{
				gMe.SetPhysics(PHYS_Falling);
			}

			for( i = 0; i < spiderFootMesh.Length; i++ )
			{
				spiderFootMesh[i].SetHidden(!isSpiderWalkActive);
			}
		}
	}
	else if( keyState == KS_Up )
	{
		if( localInput.IsKeyIsPressed( "GBA_Forward", string( newKey ) ) )
		{
			isForwardPressed=false;
		}

		if( localInput.IsKeyIsPressed( "GBA_Back", string( newKey ) ) )
		{
			isBackPressed=false;
		}
	}
}*/

defaultproperties
{
	Begin Object class=StaticMeshComponent Name=StaticMeshComp1
		StaticMesh=StaticMesh'Hats.Mesh.CycleHelm'
		Rotation=(Yaw=32768,Pitch=0,Roll=0)
		Translation=(X=0,Y=10,Z=7)
		Scale=0.5f
	End Object
	spiderBodyMesh=StaticMeshComp1

	Begin Object class=SkeletalMeshComponent Name=SkeletalMeshComp1
		SkeletalMesh=SkeletalMesh'Ritual.mesh.GoatHorns'
		Rotation=(Yaw=32768,Pitch=0,Roll=16384)
		Translation=(X=2,Y=10,Z=12)
		Scale=0.5f
	End Object
	spiderLegsMesh1=SkeletalMeshComp1

	Begin Object class=SkeletalMeshComponent Name=SkeletalMeshComp2
		SkeletalMesh=SkeletalMesh'Ritual.Mesh.GoatHorns'
		Rotation=(Yaw=32768,Pitch=0,Roll=16384)
		Translation=(X=-2,Y=10,Z=12)
		Scale=0.5f
		Scale3D=(x=-1.f, y=1.f, z=1.f)
	End Object
	spiderLegsMesh2=SkeletalMeshComp2

	Begin Object class=SkeletalMeshComponent Name=SkeletalMeshComp3
		SkeletalMesh=SkeletalMesh'Ritual.Mesh.GoatHorns'
		Rotation=(Yaw=32768,Pitch=0,Roll=16384)
		Translation=(X=1,Y=10,Z=12)
		Scale=0.4f
	End Object
	spiderLegsMesh3=SkeletalMeshComp3

	Begin Object class=SkeletalMeshComponent Name=SkeletalMeshComp4
		SkeletalMesh=SkeletalMesh'Ritual.Mesh.GoatHorns'
		Rotation=(Yaw=32768,Pitch=0,Roll=16384)
		Translation=(X=-1,Y=10,Z=12)
		Scale=0.4f
		Scale3D=(x=-1.f, y=1.f, z=1.f)
	End Object
	spiderLegsMesh4=SkeletalMeshComp4

	isSpiderWalkActive=true
}