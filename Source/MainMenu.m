#import "Constants.h"

#import "MainMenu.h"
#import "NebulaBackground.h"
#import "GameScene.h"
#import "ShipSelectionScene.h"

@implementation MainMenu {
	NebulaBackground *_background;
	CCTime _time;
	
	CCLabelTTF* _titleLabel;
	
	CCSprite* _ship1;
	CCSprite* _ship2;
	CCSprite* _ship3;
	
	CCParticleSystem *_particles;
}

+(void)initialize
{
	if(self != [MainMenu class]) return;
	
	// This doesn't really belong here, but there isn't a great platform common "just launched" location.
	[CCDirector sharedDirector].fixedUpdateInterval = 1.0/120.0;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:@{
		DefaultsMusicKey: @(1.0),
		DefaultsSoundKey: @(1.0),
	}];
	
	[OALSimpleAudio sharedInstance].bgVolume = [defaults floatForKey:DefaultsMusicKey];
	[OALSimpleAudio sharedInstance].effectsVolume = [defaults floatForKey:DefaultsSoundKey];
	
	[[OALSimpleAudio sharedInstance] playBg:@"TempMusic.aac" loop:YES];
}

-(void)didLoadFromCCB
{
	_particles = (CCParticleSystem *)[CCBReader load:@"DistortionParticles/Menu"];
	_particles.shader = [CCShader shaderNamed:@"DistortionParticle"];
	_particles.positionType = CCPositionTypeNormalized;
	_particles.position = _titleLabel.position;
	_particles.posVar = ccp(_titleLabel.contentSize.width / 2.0f, 15.0f);
	[_background.distortionNode addChild:_particles];
	
	// Make the "no physics node" warning go away.
	_ship1.physicsBody = nil;
	_ship2.physicsBody = nil;
	_ship3.physicsBody = nil;
}

-(void)update:(CCTime)delta
{
	_time += delta;
	
	// There is a simple hack in the vertex shader to make the nebula scroll.
	_background.shaderUniforms[@"u_ScrollOffset"] = [NSValue valueWithCGPoint:ccp(0.0f, fmod(_time/4.0, 1.0))];
	
	// Set up three ships moving around just for fun.
	[self setShip:_ship1 atTime:_time atOffset:0.0f];
	[self setShip:_ship2 atTime:_time  atOffset:1.0f];
	[self setShip:_ship3 atTime:_time  atOffset:-1.0f];
}

-(void) setShip:(CCSprite *) ship atTime:(CCTime) t atOffset:(float) offset
{
	float phase = (offset * M_PI * 2.0f / 3.0f);
	
	// Nice periodic motion left and right
	float xPos = sinf(t + phase);
	// Since the derivative of sin is cos, this gives us the direction of the ship.
	float shipDirection = cosf(t + phase);
	
	float yOffset = 100.0f + sinf(t / 3.0f + phase) * 40.0f;

	// They rotate +/- 15 degrees, and they need to be turned -90 degrees to face upwards
	ship.rotation = shipDirection * 15.0f - 90.0f;
	ship.position = ccp(xPos * 80.0f + offset * 30.0f + 256.0f, yOffset);
}


-(void)showShipSelector
{
	// Remove label so it doesn't show through the background and so it makes a good cinematic when we select a ship.
	[_titleLabel removeFromParent];
	[_particles removeFromParent];
	
	CCDirector *director = [CCDirector sharedDirector];
	CGSize viewSize = director.viewSize;
	
	ShipSelectionScene *newScene = (ShipSelectionScene *)[CCBReader load:@"ShipSelectionScene"];
	newScene.mainMenu = self;
	
	CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:viewSize.width height:viewSize.height];
	rt.contentScale /= 4.0;
	rt.texture.antialiased = YES;
	
	GLKMatrix4 projection = director.projectionMatrix;
	CCRenderer *renderer = [rt begin];
	[self visit:renderer parentTransform:&projection];
	[rt end];
	
	CCSprite *screenGrab = [CCSprite spriteWithTexture:rt.texture];
	screenGrab.anchorPoint = ccp(0.0, 0.0);
	screenGrab.effect = [CCEffectStack effects:
#if !CC_DIRECTOR_IOS_THREADED_RENDERING
		// BUG!
											 [CCEffectBlur effectWithBlurRadius:4.0],
#endif
											 [CCEffectSaturation effectWithSaturation:-0.5],
											 nil
											 ];
	[newScene addChild:screenGrab z:-1];
	
	[director pushScene:newScene withTransition:[CCTransition transitionCrossFadeWithDuration:0.25]];
}


-(void) launchWithShip:(ShipType) shipType;
{
	__block ShipType blockShip = shipType;
	
	
	[self scheduleBlock:^(CCTimer *timer) {
		GameScene *scene = [[GameScene alloc] initWithShipType:blockShip level:0 ];
		[[CCDirector sharedDirector] replaceScene:scene];
	}delay:2.75f];

	CCSprite *ship = @[_ship3, _ship2, _ship1][shipType];
	// The ship's motion is already controlled, so we're going to move a special parent node made just for this purpose.
	[ship.parent runAction:[CCActionMoveBy actionWithDuration:2.5f position:ccp(0.0f, 400.0f)] ];
	// but scale the ship itself.
	[ship runAction:[CCActionScaleTo actionWithDuration:2.5f scale:2.5f]];
}



@end
