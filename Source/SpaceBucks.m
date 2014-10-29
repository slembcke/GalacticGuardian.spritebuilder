#import "SpaceBucks.h"
#import "PlayerShip.h"

@implementation SpaceBucks

-(void)onEnter
{
	
	_accelRange = 20.0f;
	_accelAmount = 1.25f;
	
	CCPhysicsBody *body = self.physicsBody;
	
	// This is used to pick which collision delegate method to call, see GameScene.m for more info.
	body.collisionType = @"pickup";
	
	// This sets up simple collision rules.
	// First you list the categories (strings) that the object belongs to.
	body.collisionCategories = @[CollisionCategoryPickup];
	// Then you list which categories its allowed to collide with.
	body.collisionMask = @[CollisionCategoryPlayer];
	
	[super onEnter];
}

-(void)fixedUpdate:(CCTime)delta towardsPlayer:(PlayerShip *)player
{
	if([player isDead]) return;
	
	
	CCPhysicsBody *body = self.physicsBody;
	
	// First, apply some drag
	body.velocity = ccpMult(body.velocity, 0.9);

	if(ccpDistance(player.position, self.position) < _accelRange){
		// then consider accellerating towards player
		body.velocity = ccpAdd(body.velocity, ccpMult(ccpNormalize(ccpSub(player.position, self.position)), delta * _accelAmount));
	}
	
}

@end
