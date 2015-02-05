/*
 * Galactic Guardian
 *
 * Copyright (c) 2015 Scott Lembcke and Andy Korth
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "OALSimpleAudio.h"
#import "CCPhysics+ObjectiveChipmunk.h"

#import "Constants.h"

#import "EnemyShip.h"
#import "SpaceBucks.h"


static const NSUInteger PickupCount = 8;


@implementation EnemyShip
{
	float _speed;
	float _accelTime;
	int _originalHP;
	
	CCNode *_debrisNode;
	CCNode *_explosion;
	CCNode *_smoke;
	CCNode *_distortion;
	CCNode *_pickups[PickupCount];
	
	__unsafe_unretained GameScene *_scene;
	BOOL _dead;
}

@synthesize poolKey = _poolKey;

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
	_originalHP = _hp;
	
	CCPhysicsBody *body = self.physicsBody;
	
	// This is used to pick which collision delegate method to call, see GameScene.m for more info.
	body.collisionType = @"enemy";
	
	// This sets up simple collision rules.
	// First you list the categories (strings) that the object belongs to.
	body.collisionCategories = CollisionCategories;
	// Then you list which categories its allowed to collide with.
	body.collisionMask = CollisionMask;
	
	[self reset];
}

-(void)reset
{
	_dead = NO;
	_hp = _originalHP;
	
	CCPhysicsBody *body = self.physicsBody;
	body.angularVelocity = 0.0;
	body.collisionMask = CollisionMask;
	
	// Enemies are often destroyed in large groups (bombs, rockets), but their spawning is spread over several frames.
	// Preload their destruction objects to spread out the CPU work more evenly.
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
	
	// The enemies are dumb. They just attempt to fly towards the player.
	CGPoint desiredVelocity = ccpMult(ccpNormalize(ccpSub(_scene.playerPosition, body.absolutePosition)), _speed);
	CGPoint velocity = cpvlerpconst(body.velocity, desiredVelocity, _speed/_accelTime*delta);
	
	body.velocity = velocity;
	if(cpvlengthsq(velocity) > 0.0){
		// Rotate the enemy towards the direction it's moving.
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
	if(_dead) return;
	_dead = YES;
	
	// TODO should catch this in the collision handler instead.
	if(![self isRunningInActiveScene]){
		CCLOG(@"Probably this enemy was destroyed twice.");
		return;
	}
	
	CCPhysicsBody *body = self.physicsBody;
	
	// Tell it not to collide with anything anymore.
	body.collisionMask = @[];
	
	// Give them a little death spin.
	body.angularVelocity = 1.0;
	
	CCNode *parent = self.parent;
	GameScene *scene = _scene;
	
	// Delay destroying an enemy by a short duration.
	// For big explosions, this scatters the sound effects and CPU usage for destroying the objects.
	// It also just looks kinda cool.
	[parent scheduleBlock:^(CCTimer *timer){
		CGPoint pos = self.position;
		
		for(int i=0; i<PickupCount; i++){
			CCNode *pickup = _pickups[i];
			pickup.position = pos;
			[parent addChild:pickup z:Z_PICKUPS];
		}
		
		CCNode *debrisNode = _debrisNode;
		_debrisNode = nil;
		debrisNode.position = pos;
		debrisNode.rotation = self.rotation;
		
		InitDebris(debrisNode, debrisNode, self.physicsBody.velocity, weaponColor);
		[parent addChild:debrisNode z:Z_DEBRIS];
		
		CCNode *explosion = _explosion;
		explosion.position = pos;
		[parent addChild:explosion z:Z_FIRE];
		
		CCNode *smoke = _smoke;
		smoke.position = pos;
		[parent addChild:smoke z:Z_SMOKE];
		
		CCNode *distortion = _distortion;
		distortion.position = pos;
		[scene.distortionNode addChild:distortion];
		
		[debrisNode scheduleBlock:^(CCTimer *timer) {
			[debrisNode removeFromParent];
			[explosion removeFromParent];
			[smoke removeFromParent];
			[distortion removeFromParent];
		} delay:3.0];
		
		[[OALSimpleAudio sharedInstance] playEffect:@"TempSounds/Explosion.wav" volume:2.0 pitch:1.0 pan:0.0 loop:NO];
		
		[scene poolObject:self];
		[self removeFromParent];
	} delay:CCRANDOM_0_1()*0.25];
}

@end
