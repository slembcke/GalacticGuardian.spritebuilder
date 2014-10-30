#import "Constants.h"

@interface ShipSelectionScene : CCScene @end

@implementation ShipSelectionScene {
	CCProgressNode *shieldBar;
	CCProgressNode *speedBar;
	CCProgressNode *powerBar;
	
	CCSprite * shieldBarSprite;
	CCSprite * speedBarSprite;
	CCSprite * powerBarSprite;

	CCNode * shipNode;
	
	int _shipIndex;
	
	CCLabelTTF *shipNameLabel;
}


static NSString * const ship_names[] = {@"Retribution", @"Defiant", @"Herald"};
const float ship_shields[] = {100.0f, 100.0f, 100.0f};
const float ship_speeds[] = {100.0f, 100.0f, 100.0f};
const float ship_powers[] = {100.0f, 100.0f, 100.0f};


-(void)setupBar:(CCProgressNode *)bar fromSprite:(CCSprite *)sprite
{
	[shieldBarSprite removeFromParent];
	shieldBar = [CCProgressNode progressWithSprite:shieldBarSprite];
	shieldBar.position = [shieldBarSprite position];
	shieldBar.midpoint = ccp(0, 0.5);
	shieldBar.barChangeRate = ccp(1.0, 0.0);
	
}

-(void)didLoadFromCCB
{
	self.contentSize = [CCDirector sharedDirector].designSize;
	[self setupBar:shieldBar fromSprite:shieldBarSprite];
	[self setupBar:speedBar fromSprite:speedBarSprite];
	[self setupBar:powerBar fromSprite:powerBarSprite];
	
	[self showShip:_shipIndex];
}

-(void)dismiss:(id)sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	CCTransition *fade = [CCTransition transitionCrossFadeWithDuration:0.25];
	[[CCDirector sharedDirector] popSceneWithTransition:fade];
}

-(void) launch;
{
	
}

-(void) nextShip;
{
	
}

-(void) prevShip;
{
	
}

-(void) showShip:(ShipTypes) shipType
{
	[shipNameLabel setString: ship_names[shipType]];
	
	shieldBar.percentage = 0.0f;
	speedBar.percentage = 0.0f;
	powerBar.percentage = 0.0f;
	
	[shieldBar runAction:
	 [CCActionEaseBounce actionWithAction:
	 [CCActionTween actionWithDuration:2.0f key:@"percentage" from:0.0 to:ship_shields[shipType]]]];

	[speedBar runAction:
	 [CCActionEaseBounce actionWithAction:
	 [CCActionTween actionWithDuration:2.0f key:@"percentage" from:0.0 to:ship_speeds[shipType]]]];

	[powerBar runAction:
	 [CCActionEaseBounce actionWithAction:
	 [CCActionTween actionWithDuration:2.0f key:@"percentage" from:0.0 to:ship_powers[shipType]]]];

	
}

@end
