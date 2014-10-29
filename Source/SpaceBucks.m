#import "SpaceBucks.h"
#import "PlayerShip.h"

@implementation SpaceBucks



-(instancetype)initWithAmount:(SpaceBuckType) type
{
	NSString *spriteNames[] = {@"Sprites/Powerups/pill_blue.png", @"Sprites/Powerups/pill_green.png", @"Sprites/Powerups/pill_red.png"};
	int values[] = {1, 4, 8};
	
	if((self = [super initWithImageNamed:spriteNames[type]])){

		CCPhysicsBody *body = self.physicsBody = [CCPhysicsBody bodyWithCircleOfRadius:3.0f andCenter:CGPointZero];
		
		_accelRange = 130.0f;
		_accelAmount = 60.0f;
		_amount = values[type];
		
		// This is used to pick which collision delegate method to call, see GameScene.m for more info.
		body.collisionType = @"pickup";
		
		// This sets up simple collision rules.
		// First you list the categories (strings) that the object belongs to.
		body.collisionCategories = @[CollisionCategoryPickup];
		// Then you list which categories its allowed to collide with.
		body.collisionMask = @[CollisionCategoryPlayer, CollisionCategoryBarrier];
		body.angularVelocity = CCRANDOM_MINUS1_1() * 1.2f;
		body.velocity = ccpMult(CCRANDOM_ON_UNIT_CIRCLE(), 95.0f);
		
		
		
	}
	return self;
}


-(void)fixedUpdate:(CCTime)delta towardsPlayer:(PlayerShip *)player
{
	if([player isDead]) return;
	
	
	CCPhysicsBody *body = self.physicsBody;
	
	// First, apply some drag
	if(ccpLength(body.velocity) > 40.0f){
		body.velocity = ccpMult(body.velocity, 0.9);
	}

	if(ccpDistance(player.position, self.position) < _accelRange){
		// then consider accellerating towards player
		body.velocity = ccpAdd(body.velocity, ccpMult(ccpNormalize(ccpSub(player.position, self.position)), delta * _accelAmount));
	}
	
}

@end
