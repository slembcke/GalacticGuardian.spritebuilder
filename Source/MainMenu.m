#import "Constants.h"

#import "MainMenu.h"
#import "NebulaBackground.h"
#import "GameScene.h"

@implementation MainMenu {
	NebulaBackground *_background;
	CCTime _time;
	
	CCSprite* _ship1;
	CCSprite* _ship2;
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
	CCParticleSystem *particles = (CCParticleSystem *)[CCBReader load:@"DistortionParticles/Menu"];
	particles.shader = [CCShader shaderNamed:@"DistortionParticle"];
	particles.positionType = CCPositionTypeNormalized;
	particles.position = ccp(0.5, 0.5);
	[_background.distortionNode addChild:particles];
	
	// Make the "no physics node" warning go away.
	_ship1.physicsBody = nil;
	_ship2.physicsBody = nil;
}

-(void)update:(CCTime)delta
{
	_time += delta;
	
	// There is a simple hack in the vertex shader to make the nebula scroll.
	
	float direction = sinf(_time);
	float shipDirection = cosf(_time);
	
	_background.shaderUniforms[@"u_ScrollOffset"] = [NSValue valueWithCGPoint:ccp(direction / 8.0f, fmod(_time/4.0, 1.0))];
	_ship1.rotation = _ship2.rotation = shipDirection * 15.0f - 90.0f;
}


-(void)play:(NSString *)selectedShip
{
	GameScene *scene = [[GameScene alloc] initWithShipType:selectedShip level:0 ];
	[[CCDirector sharedDirector] replaceScene:scene];
}

-(void)ship1Selected
{
	[self play:@"AndySpaceship"];
}

-(void)ship2Selected
{
	[self play:@"ScottSpaceship"];
}


@end
