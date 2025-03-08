class SpiderGoat extends GGMutator;

var array<SpiderGoatComponent> mComponents;

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;
	local SpiderGoatComponent spiderComp;

	super.ModifyPlayer( other );

	goat = GGGoat( other );
	if( goat != none )
	{
		spiderComp=SpiderGoatComponent(GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).FindMutatorComponent(class'SpiderGoatComponent', goat.mCachedSlotNr));
		if(spiderComp != none && mComponents.Find(spiderComp) == INDEX_NONE)
		{
			mComponents.AddItem(spiderComp);
		}
	}
}

event Tick( float deltaTime )
{
	local SpiderGoatComponent sgc;

	Super.Tick( deltaTime );

	foreach mComponents(sgc)
	{
		sgc.Tick( deltaTime );
	}
}

DefaultProperties
{
	mMutatorComponentClass=class'SpiderGoatComponent'
}