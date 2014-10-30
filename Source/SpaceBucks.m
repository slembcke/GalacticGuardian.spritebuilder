#import "SpaceBucks.h"
#import "PlayerShip.h"

@implementation SpaceBucks

static NSString * const spriteNames[] = {@"Sprites/Powerups/pill_blue.png", @"Sprites/Powerups/pill_green.png", @"Sprites/Powerups/pill_red.png"};
const int values[] = {1, 4, 8};

-(instancetype)initWithAmount:(SpaceBuckType) type
{
	if((self = [super initWithImageNamed:spriteNames[type]])){
		CCPhysicsBody *body = self.physicsBody = [CCPhysicsBody bodyWithCircleOfRadius:3.0f andCenter:self.anchorPointInPoints];
		
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

const float AccelRange = 130.0;
const float AccelMin = 60.0;
const float AccelMax = 1800.0;

-(void)ggFixedUpdate:(CCTime)delta scene:(GameScene *)scene
{
	if([scene.player isDead]) return;
	
	
	CCPhysicsBody *body = self.physicsBody;
	
	// First, apply some drag
	if(ccpLength(body.velocity) > 40.0f){
		body.velocity = ccpMult(body.velocity, 0.9);
	}
	
	CGPoint targetPoint = scene.playerPosition;
	float distance = ccpDistance(targetPoint, self.position);
	
	if(distance < AccelRange){
		// then consider accellerating towards player
		float accel = AccelMin + AccelMax*(AccelRange - distance)/AccelRange;
		CGPoint direction = ccpNormalize(ccpSub(targetPoint, self.position));
		body.velocity = ccpAdd(body.velocity, ccpMult(direction, delta * accel));
	}
	
}

@end
