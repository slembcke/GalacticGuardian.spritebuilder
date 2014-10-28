#import "MainMenu.h"
#import "NebulaBackground.h"
#import "GameScene.h"

@implementation MainMenu {
	NebulaBackground *_background;
	CCTime _time;
	
	CCSprite* _ship1;
	CCSprite* _ship2;
	
}

-(void)didLoadFromCCB
{
	CCParticleSystem *particles = (CCParticleSystem *)[CCBReader load:@"DistortionParticles/Menu"];
	particles.shader = [CCShader shaderNamed:@"DistortionParticle"];
	particles.positionType = CCPositionTypeNormalized;
	particles.position = ccp(0.5, 0.5);
	[_background.distortionNode addChild:particles];
	
}

-(void)update:(CCTime)delta
{
	_time += delta;
	
	// There is a simple hack in the vertex shader to make the nebula scroll. d
	_background.shaderUniforms[@"u_ScrollOffset"] = [NSValue valueWithCGPoint:ccp(0.0, fmod(_time/4.0, 1.0))];
	_ship1.rotation = _ship2.rotation = fmod(_time * 15.0f, 360.0f) - 180.0f;
}


-(void)play:(NSString *)selectedShip
{
	GameScene *scene = [[GameScene alloc] initWithShipType:selectedShip];
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
