#import "MainMenu.h"
#import "NebulaBackground.h"

@implementation MainMenu {
	NebulaBackground *_background;
	CCTime _time;
}

-(id)init
{
	if((self = [super init])){
	}
	
	return self;
}

-(void)didLoadFromCCB
{
	CCParticleSystem *particles = (CCParticleSystem *)[CCBReader load:@"MenuParticles"];
	particles.shader = [CCShader shaderNamed:@"DistortionParticle"];
	particles.texture = [NebulaBackground distortionTexture];
	particles.positionType = CCPositionTypeNormalized;
	particles.position = ccp(0.5, 0.5);
	[_background.distortionNode addChild:particles];
	
	self.userInteractionEnabled = TRUE;
}

-(void)update:(CCTime)delta
{
	_time += delta;
	
	// There is a simple hack in the vertex shader to make the nebula scroll. d
	_background.shaderUniforms[@"u_ScrollOffset"] = [NSValue valueWithCGPoint:ccp(0.0, fmod(_time/4.0, 1.0))];
}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
	CCDirector* director = [CCDirector sharedDirector];
	[director replaceScene:[CCBReader loadAsScene:@"GameScene"]];
}


@end
