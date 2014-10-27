//
//  GameScene.m
//  Galactic Guardian
//
//  Created by Scott Lembcke
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "OALSimpleAudio.h"
#import "NebulaBackground.h"

#import "GameScene.h"

#import "PlayerShip.h"
#import "EnemyShip.h"
//#import "Bullet.h"
//#import "Asteroid.h"
#import "Joystick.h"

@implementation GameScene
{
	NebulaBackground *_background;
	CCTime _time;
	CCParticleSystem *particles;
	
	CCPhysicsNode *_physics;
	
	PlayerShip *_ship;
	
	NSMutableArray *_enemies;
	NSMutableArray *_bullets;
	
	Joystick *_joystick;
	
	NSUInteger _destroyedCount;
	
	CCLabelTTF *_warningLabel, *_scoreLabel;
}

/*
-(void)destroyBadGuy:(Asteroid *)asteroid
{
	[asteroid removeFromParent];
	[_enemies removeObject:asteroid];
	
	// Make some noise. Add a little chromatically tuned pitch bending to make it more musical.
	int half_steps = (arc4random()%(2*4 + 1) - 4);
	float pitch = pow(2.0f, half_steps/12.0f);
	[[OALSimpleAudio sharedInstance] playEffect:@"Explosion.wav" volume:1.0 pitch:pitch pan:0.0 loop:NO];
	
	// Update the score.
	_destroyedCount++;
	_scoreLabel.string = [NSString stringWithFormat:@"Score: %d", _destroyedCount*100];
	
	// If all the asteroids are destroyed, move to the next level.
	if(_asteroids.count == 0){
		[_warningLabel runAction:[CCActionBlink actionWithDuration:2.0 blinks:4]];
		
		// Add some more asteroids after a short delay
		[self scheduleBlock:^(CCTimer *timer){
			[self addAsteroids];
		} delay:2.0];
	}
}
 */

-(void)onEnter
{	
	CGSize size = self.contentSizeInPoints;
	CGPoint center = ccp(size.width/2, size.height/2);
	
	// Add a ship in the middle of the screen.
	_ship = (PlayerShip *)[CCBReader load:_selectedPlayerShip];
	_ship.position = center;
	[_physics addChild:_ship];
	
	// Reset the bullets and asteroids.
	_enemies = [NSMutableArray array];
	_bullets = [NSMutableArray array];
	
	CGFloat joystickOffset = [CCDirector sharedDirector].viewSize.width/4.0;
	_joystick = [[Joystick alloc] initWithSize:joystickOffset];
	_joystick.position = ccp(joystickOffset, joystickOffset);
	[self addChild:_joystick];
	
	// Use the gamescene as the collision delegate.
	// See the ccPhysicsCollision* methods below.
//	_physics.collisionDelegate = self;
	
	// Enable to show debug outlines for Physics shapes.
	//	_physics.debugDraw = YES;
	
	// Enable touch events.
	// The entire scene is used as a shoot button.
	self.userInteractionEnabled = YES;
	
	[super onEnter];
}

-(void)fixedUpdate:(CCTime)delta
{
	// Fly the ship using the joystick controls.
	[_ship fixedUpdate:delta withInput:_joystick.value];
	
	for (EnemyShip *e in _enemies) {
		[e fixedUpdate:delta towardsPlayer:_ship.position];
	}
	
}

/*
-(void)destroyBullet:(Bullet *)bullet
{
	[bullet removeFromParent];
	[_bullets removeObject:bullet];
	
	// Draw a little flash at it's last position
	CCSprite *sprite = [CCSprite spriteWithImageNamed:@"ShipParts/laserGreenShot.png"];
	sprite.position = bullet.position;
	[self addChild:sprite];
	
	float duration = 0.15;
	[sprite runAction:[CCActionSequence actions:
										 [CCActionSpawn actions:
											[CCActionFadeOut actionWithDuration:duration],
											[CCActionScaleTo actionWithDuration:duration scale:0.25],
											nil
											],
										 [CCActionRemove action],
										 nil
										 ]];
	
	// Make some noise. Add a little chromatically tuned pitch bending to make it more musical.
	int half_steps = (arc4random()%(2*4 + 1) - 4);
	float pitch = pow(2.0f, half_steps/12.0f);
	[[OALSimpleAudio sharedInstance] playEffect:@"Fizzle.wav" volume:1.0 pitch:pitch pan:0.0 loop:NO];
}

-(void)fireBullet
{
	// Don't fire bullets if the ship is destroyed.
	if(_ship == nil) return;
	
	// This is sort of a fancy math way to figure out where to fire the bullet from.
	// You could figure this out with more code, but I wanted to have fun with some maths.
	// This gets the transform of one of the "gunports" that I marked in the CCB file with a special node.
	CGAffineTransform transform = _ship.gunPortTransform;
	
	// An affine transform looks like this when written as a matrix:
	// | a, c, tx |
	// | b, d, ty |
	// The first column, (a, b), is the direction the new x-axis will point in.
	// The second column, (c, d), is the direction the new y-axis will point in.
	// The last column, (tx, ty), is the location of the origin of the new transform.
	
	// The position of the gunport is just the matrix's origin point (tx, ty).
	CGPoint position = ccp(transform.tx, transform.ty);
	
	// The original sprite pointed downwards on the y-axis.
	// So the transform's y-axis, (c, d), will point in the opposite direction of the gunport.
	// We just need to flip it around.
	CGPoint direction = ccp(-transform.c, -transform.d);
	
	// So by "fancy math" I really just meant knowing what the numbers in a CGAffineTransform are. ;)
	// When I make my own art, I like to align things on the positive x-axis to make the code "prettier".
	
	// Now we can create the bullet with the position and direction.
	Bullet *bullet = (Bullet *)[CCBReader load:@"Bullet"];
	bullet.position = position;
	bullet.rotation = -CC_RADIANS_TO_DEGREES(ccpToAngle(direction));
	
	// Make the bullet move in the direction it's pointed.
	bullet.physicsBody.velocity = ccpMult(direction, bullet.speed);
	
	[_physics addChild:bullet];
	[_bullets addObject:bullet];
	
	// Give the bullet a finite lifetime.
	[bullet scheduleBlock:^(CCTimer *timer){
		[self destroyBullet:bullet];
	} delay:bullet.duration];
	
	// Make some noise. Add a little chromatically tuned pitch bending to make it more musical.
	int half_steps = (arc4random()%(2*4 + 1) - 4);
	float pitch = pow(2.0f, half_steps/12.0f);
	[[OALSimpleAudio sharedInstance] playEffect:@"Laser.wav" volume:1.0 pitch:pitch pan:0.0 loop:NO];
}

// A static string used as a group identifier for the debris.
static NSString *debrisIdentifier = @"debris";

// Recursive helper function to set up physics on the debris child nodes.
static void
InitDebris(CCNode *node, CGPoint velocity)
{
	// If the node has a body, set some properties.
	CCPhysicsBody *body = node.physicsBody;
	if(body){
		// Bodies with the same group reference don't collide.
		// Any type of object will do. It's the object reference that is important.
		body.collisionGroup = debrisIdentifier;
		
		// Copy the velocity onto the body + a little random.
		body.velocity = ccpAdd(velocity, ccpMult(CCRANDOM_IN_UNIT_CIRCLE(), 10.0));
		body.angularVelocity = 2.0*CCRANDOM_MINUS1_1();
	}
	
	// Recurse on the children.
	for(CCNode *child in node.children) InitDebris(child, velocity);
}
*/

//MARK CCResponder methods

-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	NSLog(@"BANG BANG BANG!");
//	[self fireBullet];
}

-(void)update:(CCTime)delta
{
	_time += delta;
}


//MARK CCPhysicsCollisionDelegate methods

// "Begin" methods are only called once when objects begin to collide.
// Note how the last two parameters "ship" and "asteroid" are the same string as the collisionType values set in those classes.
/*
-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair ship:(CCNode *)ship asteroid:(Asteroid *)asteroid
{
	if([_ship takeDamage]){
		//The ship was destroyed!
		
		[_ship removeFromParent];
		
		CCNode *debris = [CCBReader load:@"CrashedShip"];
		debris.position = _ship.position;
		debris.rotation = _ship.rotation;
		InitDebris(debris, _ship.physicsBody.velocity);
		[_physics addChild:debris];
		
		// Add a lame particle effect.
		CCNode *explosion = [CCBReader load:@"Explosion"];
		explosion.position = _ship.position;
		[self addChild:explosion];
		
		_ship = nil;
		
		[self scheduleBlock:^(CCTimer *timer){
			// Go back to the menu after a short delay.
			[[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"MainScene"]];
		} delay:3.0];
		
		// Don't process the collision so the debris will get a chance to collide with the asteroid.
		return NO;
	} else {
		// The ship still had it's shield, destroy the asteroid instead.
		[self destroyAsteroid:asteroid];
		
		// Process the collision normally so the ship will bounce off the asteroid.
		return YES;
	}
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair bullet:(Bullet *)bullet asteroid:(Asteroid *)asteroid
{
	[self destroyBullet:bullet];
	[self destroyAsteroid:asteroid];
	
	return NO;
}
*/

@end
