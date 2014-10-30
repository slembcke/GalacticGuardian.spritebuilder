#import "CCPhysics+ObjectiveChipmunk.h"

#import "Constants.h"

#import "Rocket.h"

#import "GameScene.h"


const float RocketAcceleration = 1000.0;


@implementation Rocket {
	RocketLevel _level;
}

+(instancetype)rocketWithLevel:(RocketLevel)level
{
	Rocket *rocket = (Rocket *)[CCBReader load:@"Rocket"];
	rocket->_level = level;
	
	CCPhysicsBody *body = rocket.physicsBody;
	body.collisionType = @"rocket";
	body.collisionCategories = @[CollisionCategoryBullet];
	body.collisionMask = @[CollisionCategoryEnemy, CollisionCategoryAsteroid];
	
	float distance = 150.0;
	CCTime fuse = sqrt(2.0*distance/RocketAcceleration);
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

-(void)destroy
{
	CGPoint pos = self.position;
	GameScene *scene = (GameScene *)self.scene;
	
	[scene splashDamageAt:pos radius:100.0 damage:10];
	
	CCNode *explosion = [CCBReader load:@"Particles/RocketExplosion"];
	explosion.position = pos;
	[self.parent addChild:explosion z:Z_PARTICLES];
	
	CCNode *distortion = [CCBReader load:@"DistortionParticles/RocketRing"];
	distortion.position = pos;
	[scene.distortionNode addChild:distortion];
	
	[self scheduleBlock:^(CCTimer *timer) {
		[explosion removeFromParent];
		[distortion removeFromParent];
	} delay:2];
	
	[self removeFromParent];
}

@end
