class SpiderWebComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var GGCrosshairActor mCrosshairActor;
var bool oldCanRagdollByVelocityOrImpact;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		if(mCrosshairActor == none)
		{
			mCrosshairActor = gMe.Spawn(class'GGCrosshairActor');
			mCrosshairActor.SetColor(MakeLinearColor( 1.f, 1.f, 1.f, 1.0f ));
		}
	}
}

function DetachFromPlayer()
{
	mCrosshairActor.DestroyCrosshair();
	super.DetachFromPlayer();
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if( localInput.IsKeyIsPressed( "GBA_AbilityBite", string( newKey ) ) )
		{
			gMe.UseGrapplingHook();
		}
	}
}

function OnGrapple( Actor grapplingActor, Actor grappledActor, bool isGrappling )
{
	if(grapplingActor == gMe)
	{
		if(isGrappling)
		{
			oldCanRagdollByVelocityOrImpact=gMe.mCanRagdollByVelocityOrImpact;
			gMe.mCanRagdollByVelocityOrImpact=false;
			grappledActor.CustomTimeDilation=0.25f;
		}
		else
		{
			gMe.mCanRagdollByVelocityOrImpact=oldCanRagdollByVelocityOrImpact;
			grappledActor.CustomTimeDilation=grappledActor.default.CustomTimeDilation;
		}
	}
}

simulated event TickMutatorComponent( float delta )
{
	UpdateCrosshair();

	if(gMe.mGrabbedItem != none && gMe.mGrapplingHook.IsGrappling())
	{
		gMe.ReleaseGrapplingHook();
	}
}

function UpdateCrosshair()
{
	local vector			StartTrace, EndTrace, AdjustedAim, camLocation, hitLocation, hitNormal;
	local rotator 			camRotation;
	local float 			Radius;
	local Actor				hitActor;

	if(gMe != None)
	{
		GGPlayerControllerGame( gMe.Controller ).PlayerCamera.GetCameraViewPoint( camLocation, camRotation );
		StartTrace = camLocation;

		AdjustedAim = vector(camRotation);

		Radius = mCrosshairActor.SkeletalMeshComponent.SkeletalMesh.Bounds.SphereRadius;
		EndTrace = StartTrace + AdjustedAim * (gMe.mGrapplingHook.mRange - Radius);

		hitActor = gMe.Trace( hitLocation, hitNormal, EndTrace, StartTrace);
		if(hitActor == none) hitLocation=EndTrace;

		mCrosshairActor.UpdateCrosshair(hitLocation, -AdjustedAim);
	}
}

defaultproperties
{

}