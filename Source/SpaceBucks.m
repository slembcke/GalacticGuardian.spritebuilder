#import "CCPhysics+ObjectiveChipmunk.h"

#import "SpaceBucks.h"
#import "PlayerShip.h"

@implementation SpaceBucks {
	GameScene *_scene;
}

static NSString * const spriteNames[] = {@"Sprites/Powerups/pill_blue.png", @"Sprites/Powerups/pill_green.png", @"Sprites/Powerups/pill_red.png"};
static NSString * const spriteFlashes[] = {@"Sprites/Bullets/laserBlue08.png", @"Sprites/Bullets/laserGreen14.png", @"Sprites/Bullets/laserRed08.png"};
const int values[] = {1, 4, 8};

-(instancetype)initWithAmount:(SpaceBuckType) type
{
	if((self = [super initWithImageNamed:spriteNames[type]])){
		CCPhysicsBody *body = self.physicsBody = [CCPhysicsBody bodyWithCircleOfRadius:3.0f andCenter:self.anchorPointInPoints];
		
		_amount = values[type];
		_flashImage = spriteFlashes[type];
		
		// This is used to pick which collision delegate method to call, see GameScene.m for more info.
		body.collisionType = @"pickup";
		
		// This sets up simple collision rules.
		// First you list the categories (strings) that the object belongs to.
		body.collisionCategories = @[CollisionCategoryPickup];
		// Then you list which categories its allowed to collide with.
		body.collisionMask = @[CollisionCategoryPlayer, CollisionCategoryBarrier];
		body.angularVelocity = CCRANDOM_MINUS1_1() * 20.0f;
		body.velocity = ccpMult(CCRANDOM_IN_UNIT_CIRCLE(), 200.0f);
	}
	return self;
}

-(void)onEnter
{
	_scene = (GameScene *)self.scene;
	
	[self scheduleBlock:^(CCTimer *timer) {
		[self runAction:[CCActionSequence actions:
			[CCActionFadeOut actionWithDuration:0.25],
			[CCActionRemove action],
			nil
		]];
	} delay:5.0 + CCRANDOM_0_1()];
	[super onEnter];
}

const float AccelRange = 130.0;
const float AccelMin = 60.0;
const float AccelMax = 600.0;

-(void)fixedUpdate:(CCTime)delta
{
	if([_scene.playerShip isDead]) return;
		
	CCPhysicsBody *body = self.physicsBody;
	CGPoint pos = body.absolutePosition;
	
	// Check if it's gone offscreen and remove it.
	if(!CGRectContainsPoint(CGRectMake(0.0, 0.0, GameSceneSize, GameSceneSize), pos)){
		[self removeFromParent];
		return;
	}
	
	// First, apply some drag
	if(ccpLength(body.velocity) > 40.0f){
		body.velocity = ccpMult(body.velocity, pow(0.25, delta));
	}
	
	CGPoint targetPoint = _scene.playerPosition;
	float distance = ccpDistance(targetPoint, pos);
	
	if(distance < AccelRange){
		// then consider accellerating towards player
		float accel = AccelMin + AccelMax*(AccelRange - distance)/AccelRange;
		CGPoint direction = ccpNormalize(ccpSub(targetPoint, self.position));
		body.velocity = ccpAdd(body.velocity, ccpMult(direction, delta * accel));
	}
}

@end
