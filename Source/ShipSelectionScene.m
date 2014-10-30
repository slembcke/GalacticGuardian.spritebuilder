#import "Constants.h"
#import "ShipSelectionScene.h"

@implementation ShipSelectionScene {
	CCProgressNode *shieldBar;
	CCProgressNode *speedBar;
	CCProgressNode *powerBar;
	
	CCSprite * shieldBarSprite;
	CCSprite * speedBarSprite;
	CCSprite * powerBarSprite;

	CCNode * _shipNode;
	CCNode * _viewNode;
	
	int _shipIndex;
	
	CCLabelTTF *shipNameLabel;
	
}

const float ship_shields[] = {60.0f, 70.0f, 20.0f};
const float ship_speeds[] = {100.0f, 40.0f, 70.0f};
const float ship_powers[] = {30.0f, 80.0f, 100.0f};


-(CCProgressNode *)setupBarFromSprite:(CCSprite *)sprite
{
	[sprite removeFromParent];
	CCProgressNode * bar = [CCProgressNode progressWithSprite:sprite];
	bar.type = CCProgressNodeTypeBar;
	bar.midpoint = CGPointZero;
	bar.barChangeRate = ccp(1.0f, 0.0f);
	bar.positionType = [sprite positionType];
	bar.scale = [sprite scale];
	bar.position = [sprite position];
	[_viewNode addChild:bar];
	return bar;
}

-(void)didLoadFromCCB
{
	self.contentSize = [CCDirector sharedDirector].designSize;
	self.contentSizeType = CCSizeTypePoints;
	
	// Make the "no physics node" warning go away.
	_shipNode.physicsBody = nil;
	
	shieldBar = [self setupBarFromSprite:shieldBarSprite];
	speedBar  = [self setupBarFromSprite:speedBarSprite];
	powerBar  = [self setupBarFromSprite:powerBarSprite];
	
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
	CCTransition *fade = [CCTransition transitionCrossFadeWithDuration:0.25];
	[[CCDirector sharedDirector] popSceneWithTransition:fade];
	
	[_mainMenu launchWithShip:_shipIndex];
}

-(void) nextShip;
{
	_shipIndex = (_shipIndex + 1) % 3;
	[self showShip:_shipIndex];
}

-(void) prevShip;
{
	_shipIndex = (_shipIndex - 1 + 3) % 3;
	[self showShip:_shipIndex];
}

-(void) showShip:(ShipType) shipType
{
	[_shipNode removeFromParent];
	CCNode *oldShip = _shipNode;
	{
		float rotation = 0.0f;
		rotation = _shipNode.rotation;

		int shipChassis = 1;
		NSString * shipArt = ship_fileNames[shipType];
		_shipNode = [CCBReader load:[NSString stringWithFormat:@"%@-%d", shipArt, shipChassis ]];
		_shipNode.position = [oldShip position];
		_shipNode.scale = 2.0f;
		_shipNode.physicsBody = nil;
		[_viewNode addChild:_shipNode];
	}
	
	[shipNameLabel setString: ship_names[shipType]];
	
	shieldBar.percentage = 0.0f;
	speedBar.percentage = 0.0f;
	powerBar.percentage = 0.0f;
	
	[shieldBar runAction:
	 // TODO: EaseBounce has no effect, apparently?
	 [CCActionEaseBounce actionWithAction:
	 [CCActionTween actionWithDuration:1.0f key:@"percentage" from:0.0 to:ship_shields[shipType]]]];

	[speedBar runAction:
	 [CCActionEaseBounce actionWithAction:
	 [CCActionTween actionWithDuration:1.0f key:@"percentage" from:0.0 to:ship_speeds[shipType]]]];

	[powerBar runAction:
	 [CCActionEaseBounce actionWithAction:
	 [CCActionTween actionWithDuration:1.0f key:@"percentage" from:0.0 to:ship_powers[shipType]]]];

	
}

@end
