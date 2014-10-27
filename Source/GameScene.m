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
#import "Bullet.h"
#import "Joystick.h"


static CGSize GameSceneSize = {1024, 1024};

enum ZORDER {
	Z_SCROLL_NODE,
	Z_NEBULA,
	Z_PHYSICS,
	Z_ENEMY,
	Z_PLAYER,
	Z_JOYSTICK,
};


@implementation GameScene
{
	CCNode *_scrollNode;
	CGPoint _minScrollPos, _maxScrollPos;
	
	CCPhysicsNode *_physics;
	NebulaBackground *_background;
	
	Joystick *_joystick;
	PlayerShip *_playerShip;
	
	NSMutableArray *_enemies;
	
	int _enemies_killed;
}

-(instancetype)initWithShipType:(NSString *)shipType
{
	if((self = [super init])){
		CGSize viewSize = [CCDirector sharedDirector].viewSize;
		
		CGFloat joystickOffset = viewSize.width/8.0;
		_joystick = [[Joystick alloc] initWithSize:joystickOffset];
		_joystick.position = ccp(joystickOffset, joystickOffset);
		[self addChild:_joystick z:Z_JOYSTICK];
		
		_scrollNode = [CCNode node];
		_scrollNode.contentSize = CGSizeMake(1.0, 1.0);
		_scrollNode.position = ccp(viewSize.width/2.0, viewSize.height/2.0);
		[self addChild:_scrollNode z:Z_SCROLL_NODE];
		
		_minScrollPos = ccp(viewSize.width/2.0, viewSize.height/2.0);
		_maxScrollPos = ccp(GameSceneSize.width - _minScrollPos.x, GameSceneSize.height - _minScrollPos.y);
		
		NebulaBackground *nebula = [NebulaBackground node];
		nebula.contentSize = GameSceneSize;
		[_scrollNode addChild:nebula z:Z_NEBULA];
		
		_physics = [CCPhysicsNode node];
		[_scrollNode addChild:_physics z:Z_PHYSICS];
		
		_enemies = [NSMutableArray array];
		
		// Use the gamescene as the collision delegate.
		// See the ccPhysicsCollision* methods below.
		_physics.collisionDelegate = self;
		
		// Enable to show debug outlines for Physics shapes.
		_physics.debugDraw = YES;
		
		// Add a ship in the middle of the screen.
		_playerShip = (PlayerShip *)[CCBReader load:shipType];
		_playerShip.position = ccp(GameSceneSize.width/2.0, GameSceneSize.height/2.0);
		[_physics addChild:_playerShip z:Z_PLAYER];
		
		// Center on the player.
		_scrollNode.anchorPoint = _playerShip.position;
		
		[self scheduleBlock:^(CCTimer *timer) {
			
			EnemyShip *enemy = (EnemyShip *)[CCBReader load:@"BadGuy1"];
			enemy.position = ccp(CCRANDOM_0_1() > 0.5f ? 0 + 128.0f : 1024.0f - 128.0f, 512.0f);
			[_physics addChild:enemy z:Z_ENEMY];
			[_enemies addObject:enemy];
			
			[timer repeatOnceWithInterval:1.0f];
			
		} delay:1.0f];
		
		
		// Enable touch events.
		// The entire scene is used as a shoot button.
		self.userInteractionEnabled = YES;
	}
	
	return self;
}

-(void)fixedUpdate:(CCTime)delta
{
	// Fly the ship using the joystick controls.
	[_playerShip fixedUpdate:delta withInput:_joystick.value];
	
	for (EnemyShip *e in _enemies) {
		[e fixedUpdate:delta towardsPlayer:_playerShip.position];
	}
}

-(void)update:(CCTime)delta
{
	CGPoint pos = _playerShip.position;
	
	// Clamp the scrolling position so you can't see outside of the game area.
	_scrollNode.anchorPoint = ccp(
		MAX(_minScrollPos.x, MIN(pos.x, _maxScrollPos.x)),
		MAX(_minScrollPos.y, MIN(pos.y, _maxScrollPos.y))
	);
}


-(void)enemyDeath:(EnemyShip *)enemy
{
	[enemy removeFromParent];
	[_enemies removeObject:enemy];
	_enemies_killed += 1;
	
	// TODO Explosion!
	
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
*/

//// A static string used as a group identifier for the debris.
//static NSString *debrisIdentifier = @"debris";

// Recursive helper function to set up physics on the debris child nodes.
static void
InitDebris(CCNode *root, CCNode *node, CGPoint velocity)
{
	// If the node has a body, set some properties.
	CCPhysicsBody *body = node.physicsBody;
	if(body){
		// Bodies with the same group reference don't collide.
		// Any type of object will do. It's the object reference that is important.
		// In this case, I want the debris to collide with everything except other debris from the same ship.
		// I'll use a reference to the root node since that is unique for each explosion.
		body.collisionGroup = root;
		
		// Copy the velocity onto the body + a little random.
		body.velocity = ccpAdd(velocity, ccpMult(CCRANDOM_IN_UNIT_CIRCLE(), 10.0));
		body.angularVelocity = 2.0*CCRANDOM_MINUS1_1();
	}
	
	// Recurse on the children.
	for(CCNode *child in node.children) InitDebris(root, child, velocity);
}

//MARK CCResponder methods

-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	NSLog(@"BANG BANG BANG!");
//	[self fireBullet];
}

#pragma mark - CCPhysicsCollisionDelegate methods


-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair ship:(PlayerShip *)player enemy:(EnemyShip *)enemy
{
	if([_playerShip takeDamage]){
		//The ship was destroyed!
		[_playerShip removeFromParent];
		
		CCNode *debris = [CCBReader load:_playerShip.debris];
		debris.position = _playerShip.position;
		debris.rotation = _playerShip.rotation;
		InitDebris(debris, debris, _playerShip.physicsBody.velocity);
		[_physics addChild:debris];
		
		[debris scheduleBlock:^(CCTimer *timer) {
			[debris removeFromParent];
		} delay:5];
		
		// Add a lame particle effect.
//		CCNode *explosion = [CCBReader load:@"Explosion"];
//		explosion.position = _ship.position;
//		[self addChild:explosion];
//		
//		_playerShip = nil;
		
		[self scheduleBlock:^(CCTimer *timer){
			// Go back to the menu after a short delay.
			[[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"MainMenu"]];
		} delay:1.0]; // TODO: nonzero delay needed for optimal fun
		
		// Don't process the collision so the enemy spaceship will survive and mock you.
		return NO;
	}else{
		// Player took damage, the enemy should self destruct.
		[self enemyDeath: enemy];
		return YES;
	}
	
	
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair bullet:(Bullet *)bullet enemy:(EnemyShip *)enemy
{
//	[self destroyBullet:bullet];
	
	if([enemy takeDamage]){
		[self enemyDeath:enemy];
	}
	
	return NO;
}


@end
