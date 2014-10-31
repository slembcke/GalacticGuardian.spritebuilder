#import "CCPhysics+ObjectiveChipmunk.h"

#import "Constants.h"

#import "Rocket.h"

#import "GameScene.h"


static const float RocketAcceleration = 1000.0;
static const float RocketDistance = 125.0;

static const float RocketDamage[] = {7.0, 10.0, 3.0};
static const float RocketSplash = 150.0;

static const int RocketClusters = 5;
static const CCTime RocketClusterDelay = 0.3;
static const CCTime RocketClusterInterval = 0.05;
static const float RocketClusterRange = 50.0;


@implementation Rocket {
	RocketLevel _level;
}

+(instancetype)rocketWithLevel:(RocketLevel)level
{
	Rocket *rocket = (Rocket *)[CCBReader load:@"Rocket"];
	rocket->_level = level;
	
	CGSize size = rocket.contentSize;
	CGFloat radius = size.height/2.0;
	
	CCPhysicsBody *body = rocket.physicsBody = [CCPhysicsBody bodyWithPillFrom:ccp(radius, radius) to:ccp(size.width - radius, radius) cornerRadius:radius];
	body.collisionType = @"rocket";
	body.collisionCategories = @[CollisionCategoryBullet];
	body.collisionMask = @[CollisionCategoryEnemy, CollisionCategoryAsteroid];
	
	CCTime fuse = sqrt(2.0*RocketDistance/RocketAcceleration);
	[rocket scheduleBlock:^(CCTimer *timer) {
		[rocket destroy];
	} delay:fuse];
	
	return rocket;
}

-(void)fixedUpdate:(CCTime)delta
{
	CCPhysicsBody *body = self.physicsBody;
	CGAffineTransform transform = body.absoluteTransform;
	
	CGPoint direction = CGPointMake(transform.a, transform.b);
	body.velocity = ccpAdd(body.velocity, ccpMult(direction, RocketAcceleration*delta));
}

-(void)splashAt:(CGPoint)pos parent:(CCNode *)parent
{
	GameScene *scene = (GameScene *)parent.scene;
	[scene splashDamageAt:pos radius:RocketSplash damage:RocketDamage[_level]];
	
	CCNode *explosion = [CCBReader load:@"Particles/RocketExplosion"];
	explosion.position = pos;
	[parent addChild:explosion z:Z_FIRE];
	
	CCNode *smoke = [CCBReader load:@"Particles/Smoke"];
	smoke.position = pos;
	[parent addChild:smoke z:Z_SMOKE];
	
	CCNode *distortion = [CCBReader load:@"DistortionParticles/RocketRing"];
	distortion.position = pos;
	[scene.distortionNode addChild:distortion];
	
	[scene scheduleBlock:^(CCTimer *timer) {
		[explosion removeFromParent];
		[smoke removeFromParent];
		[distortion removeFromParent];
	} delay:2];
	
	[[OALSimpleAudio sharedInstance] playEffect:@"TempSounds/Explosion.wav" volume:2.0 pitch:1.0 pan:0.0 loop:NO];
}

-(void)destroy
{
	CCNode *parent = self.parent;
	CGPoint pos = self.position;
	
	[self splashAt:pos parent:parent];
	
	if(_level == RocketCluster){
		for(int i=1; i<RocketClusters; i++){
			[parent scheduleBlock:^(CCTimer *timer) {
				CGPoint splashPos = ccpAdd(pos, ccpMult(CCRANDOM_ON_UNIT_CIRCLE(), RocketClusterRange));
				[self splashAt:splashPos parent:parent];
			} delay:i*RocketClusterInterval + RocketClusterDelay];
		}
	}
	
	[self removeFromParent];
}

@end
