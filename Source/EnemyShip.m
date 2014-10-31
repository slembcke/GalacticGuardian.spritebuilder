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
}

-(void)onEnter
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
	
	[super onEnter];
}

// This method is called from [GameScene fixedUpdate:], not from Cocos2D.
-(void)ggFixedUpdate:(CCTime)delta scene:(GameScene *)scene
{
	if(_hp == 0 || [scene.player isDead]) return;
	
	CCPhysicsBody *body = self.physicsBody;
	
	CGPoint targetVelocity = ccpMult(ccpNormalize(ccpSub(scene.playerPosition, self.position)), _speed);
	
	CGPoint velocity = cpvlerpconst(body.velocity, targetVelocity, _speed/_accelTime*delta);
	
	//	CCLOG(@"velocity: %@", NSStringFromCGPoint(velocity));
	
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
	
	// spawn loot:
	for(int i = 0; i < 10; i++){
		SpaceBuckType type = SpaceBuck_1;
		float n = CCRANDOM_0_1();
		if(n > 0.90f){
			type = SpaceBuck_8;
		}else if ( n > 0.70f){
			type = SpaceBuck_4;
		}
		
		SpaceBucks *pickup = [[SpaceBucks alloc] initWithAmount: type];
		pickup.position = pos;
		[parent addChild:pickup z:Z_PICKUPS];
	}
	
	CCNode *debris = [CCBReader load:self.debris];
	debris.position = pos;
	debris.rotation = self.rotation;
	
	InitDebris(debris, debris, self.physicsBody.velocity, weaponColor);
	[parent addChild:debris z:Z_DEBRIS];
	
	CCNode *explosion = [CCBReader load:@"Particles/ShipExplosion"];
	explosion.position = pos;
	[parent addChild:explosion z:Z_FIRE];
	
	CCNode *smoke = [CCBReader load:@"Particles/Smoke"];
	smoke.position = pos;
	[parent addChild:smoke z:Z_SMOKE];
	
	CCNode *distortion = [CCBReader load:@"DistortionParticles/SmallRing"];
	distortion.position = pos;
	[scene.distortionNode addChild:distortion];
	
	[parent scheduleBlock:^(CCTimer *timer) {
		[debris removeFromParent];
		[explosion removeFromParent];
		[smoke removeFromParent];
		[distortion removeFromParent];
	} delay:3.0];
	
	[[OALSimpleAudio sharedInstance] playEffect:@"TempSounds/Explosion.wav" volume:2.0 pitch:1.0 pan:0.0 loop:NO];
	
	[self removeFromParent];
}

@end