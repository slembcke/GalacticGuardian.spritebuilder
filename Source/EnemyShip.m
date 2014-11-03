//  Created by Andy Korth on 10/27/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "OALSimpleAudio.h"
#import "CCPhysics+ObjectiveChipmunk.h"

#import "Constants.h"

#import "EnemyShip.h"
#import "SpaceBucks.h"


static const NSUInteger PickupCount = 5;


@implementation EnemyShip
{
	float _speed;
	float _accelTime;

	
	CCNode *_debrisNode;
	CCNode *_explosion;
	CCNode *_smoke;
	CCNode *_distortion;
	CCNode *_pickups[PickupCount];
	
	__unsafe_unretained GameScene *_scene;
}

static NSArray *CollisionCategories = nil;
static NSArray *CollisionMask = nil;

+(void)initialize
{
	if(self != [EnemyShip class]) return;
	
	CollisionCategories = @[CollisionCategoryEnemy];
	CollisionMask = @[
		CollisionCategoryPlayer,
		CollisionCategoryBullet,
		CollisionCategoryEnemy
	];
}

-(void)didLoadFromCCB
{
	CCPhysicsBody *body = self.physicsBody;
	
	// This is used to pick which collision delegate method to call, see GameScene.m for more info.
	body.collisionType = @"enemy";
	
	// This sets up simple collision rules.
	// First you list the categories (strings) that the object belongs to.
	body.collisionCategories = CollisionCategories;
	// Then you list which categories its allowed to collide with.
	body.collisionMask = CollisionMask;
	
	// Preload some of the destruction assets now since ships are often destroyed at the same time.
	_debrisNode = [CCBReader load:self.debris];
	_explosion = [CCBReader load:@"Particles/ShipExplosion"];
	_smoke = [CCBReader load:@"Particles/Smoke"];
	_distortion = [CCBReader load:@"DistortionParticles/SmallRing"];
	
	for(int i = 0; i < PickupCount; i++){
		SpaceBuckType type = SpaceBuck_1;
		float n = CCRANDOM_0_1();
		if(n > 0.90f){
			type = SpaceBuck_8;
		}else if ( n > 0.70f){
			type = SpaceBuck_4;
		}
		
		_pickups[i] = [[SpaceBucks alloc] initWithAmount:type];
	}
}

-(void)onEnter
{
	_scene = (GameScene *)self.scene;
	[super onEnter];
}

-(void)fixedUpdate:(CCTime)delta
{
	if(_hp == 0 || _scene.playerShip.isDead) return;
	
	CCPhysicsBody *body = self.physicsBody;
	
	CGPoint targetVelocity = ccpMult(ccpNormalize(ccpSub(_scene.playerPosition, body.absolutePosition)), _speed);
	CGPoint velocity = cpvlerpconst(body.velocity, targetVelocity, _speed/_accelTime*delta);
	
	body.velocity = velocity;
	if(cpvlengthsq(velocity) > 0.0){
		const float maxTurn = 360.0*delta;
		CGPoint relativeDirection = cpTransformVect(cpTransformInverse(body.absoluteTransform), velocity);
		self.rotation += clampf(-CC_RADIANS_TO_DEGREES(ccpToAngle(relativeDirection)), -maxTurn, maxTurn);
	}
}

-(BOOL) takeDamage:(int)damage
{
	_hp -= damage;
	return _hp <= 0;
}

-(void)destroyWithWeaponColor:(CCColor *)weaponColor
{
	// TODO should catch this in the collision handler instead.
	if(![self isRunningInActiveScene]){
		NSLog(@"Probably this enemy was destroyed twice.");
		return;
	}
	
	CCNode *parent = self.parent;
	CGPoint pos = self.position;
	
	for(int i=0; i<PickupCount; i++){
		CCNode *pickup = _pickups[i];
		pickup.position = pos;
		[parent addChild:pickup z:Z_PICKUPS];
	}
	
	_debrisNode.position = pos;
	_debrisNode.rotation = self.rotation;
	
	InitDebris(_debrisNode, _debrisNode, self.physicsBody.velocity, weaponColor);
	[parent addChild:_debrisNode z:Z_DEBRIS];
	
	_explosion.position = pos;
	[parent addChild:_explosion z:Z_FIRE];
	
	_smoke.position = pos;
	[parent addChild:_smoke z:Z_SMOKE];
	
	_distortion.position = pos;
	[_scene.distortionNode addChild:_distortion];
	
	[parent scheduleBlock:^(CCTimer *timer) {
		[_debrisNode removeFromParent];
		[_explosion removeFromParent];
		[_smoke removeFromParent];
		[_distortion removeFromParent];
	} delay:3.0];
	
	[[OALSimpleAudio sharedInstance] playEffect:@"TempSounds/Explosion.wav" volume:2.0 pitch:1.0 pan:0.0 loop:NO];
	
	[self removeFromParent];
}

@end