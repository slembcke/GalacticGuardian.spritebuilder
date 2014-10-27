#import "GameScene.h"
#import "NebulaBackground.h"

@implementation GameScene {
	NebulaBackground *_background;
	CCTime _time;
	
	CCParticleSystem *particles;
	
}

-(id)init
{
	if((self = [super init])){
	}
	
	return self;
}

-(void)didLoadFromCCB
{
//	CCParticleSystem *particles = (CCParticleSystem *)[CCBReader load:@"MenuParticles"];
//	particles.shader = [CCShader shaderNamed:@"DistortionParticle"];
//	particles.texture = [NebulaBackground distortionTexture];
//	particles.positionType = CCPositionTypeNormalized;
//	particles.position = ccp(0.5, 0.5);
//	[_background.distortionNode addChild:particles];
}

-(void)update:(CCTime)delta
{
	_time += delta;
}

@end
