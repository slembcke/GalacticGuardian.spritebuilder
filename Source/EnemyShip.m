//  Created by Andy Korth on 10/27/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "OALSimpleAudio.h"
#import "CCPhysics+ObjectiveChipmunk.h"

#import "Constants.h"

#import "EnemyShip.h"
#import "SpaceBucks.h"

@implementation EnemyShip
{
	CCNode *_mainThruster;
	
	float _speed;
	float _accelTime;
	int _hp;
	
	CCNode *_debrisNode;
	CCNode *_explosion;
	CCNode *_smoke;
	CCNode *_distortion;
	NSArray *_pickups;
}

-(void)didLoadFromCCB
{
	CCPhysicsBody *body = self.physicsBody;
	
	_hp = 5;
	_speed = 50;
	
	// This is used to pick which collision delegate method to call, see GameScene.m for more info.
	body.collisionType = @"enemy";
	
	// This sets up simple collision rules.
	// First you list the categories (strings) that the object belongs to.
	body.collisionCategories = @[CollisionCategoryEnemy];
	// Then you list which categories its allowed to collide with.
	body.collisionMask = @[
		CollisionCategoryPlayer,
		CollisionCategoryDebris,
		CollisionCategoryBullet,
		CollisionCategoryEnemy
	];
	
	// Make the thruster pulse
	float scaleX = _mainThruster.scaleX;
	float scaleY = _mainThruster.scaleY;
	[_mainThruster runAction:[CCActionRepeatForever actionWithAction:[CCActionSequence actions:
		[CCActionScaleTo actionWithDuration:0.1 scaleX:scaleX scaleY:0.5*scaleY],
		[CCActionScaleTo actionWithDuration:0.05 scaleX:scaleX scaleY:scaleY],
		nil
	]]];
	
	// Preload some of the destruction assets now since ships are often destroyed at the same time.
	_debrisNode = [CCBReader load:self.debris];
	_explosion = [CCBReader load:@"Particles/ShipExplosion"];
	_smoke = [CCBReader load:@"Particles/Smoke"];
	_distortion = [CCBReader load:@"DistortionParticles/SmallRing"];
	
	const NSUInteger pickupCount = 10;
	SpaceBucks *pickups[pickupCount];
	
	for(int i = 0; i < 10; i++){
		SpaceBuckType type = SpaceBuck_1;
		float n = CCRANDOM_0_1();
		if(n > 0.90f){
			type = SpaceBuck_8;
		}else if ( n > 0.70f){
			type = SpaceBuck_4;
		}
		
		pickups[i] = [[SpaceBucks alloc] initWithAmount:type];
	}
	
	_pickups = [NSArray arrayWithObjects:pickups count:pickupCount];
}

-(void)fixedUpdate:(CCTime)delta
{
	GameScene *scene = (GameScene *)self.scene;
	if(_hp == 0 || [scene.player isDead]) return;
	
	CCPhysicsBody *body = self.physicsBody;
	
	CGPoint targetVelocity = ccpMult(ccpNormalize(ccpSub(scene.playerPosition, self.position)), _speed);
	CGPoint velocity = cpvlerpconst(body.velocity, targetVelocity, _speed/_accelTime*delta);
	
	body.velocity = velocity;
	if(cpvlengthsq(velocity)){
		self.rotation = -CC_RADIANS_TO_DEGREES(atan2f(velocity.y, velocity.x));
		_mainThruster.visible = YES;
	} else {
		_mainThruster.visible = NO;
	}
}

-(BOOL) takeDamage:(int)damage
{
	_hp -= damage;
	return _hp <= 0;
}

-(void)destroyWithWeaponColor:(CCColor *)weaponColor
{
	GameScene *scene = (GameScene *)self.scene;
	CCNode *parent = self.parent;
	CGPoint pos = self.position;
	
	for(int i = 0; i < 10; i++){
		SpaceBuckType type = SpaceBuck_1;
		float n = CCRANDOM_0_1();
		if(n > 0.90f){
			type = SpaceBuck_8;
		}else if ( n > 0.70f){
			type = SpaceBuck_4;
		}
		
		SpaceBucks *pickup = [[SpaceBucks alloc] initWithAmount:type];
		pickup.position = pos;
		[parent addChild:pickup z:Z_PICKUPS];
	}
//	for(SpaceBucks *pickup in _pickups){
//		pickup.position = pos;
//		[parent addChild:pickup z:Z_PICKUPS];
//	}
	
	_debrisNode.position = pos;
	_debrisNode.rotation = self.rotation;
	
	InitDebris(_debrisNode, _debrisNode, self.physicsBody.velocity, weaponColor);
	[parent addChild:_debrisNode z:Z_DEBRIS];
	
	_explosion.position = pos;
	[parent addChild:_explosion z:Z_FIRE];
	
	_smoke.position = pos;
	[parent addChild:_smoke z:Z_SMOKE];
	
	_distortion.position = pos;
	[scene.distortionNode addChild:_distortion];
	
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