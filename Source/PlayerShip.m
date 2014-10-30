//
//  MyShip.m
//  GalacticGuardian
//
//  Created by Andy Korth on 10/27/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "OALSimpleAudio.h"

#import "Constants.h"

#import "PlayerShip.h"
#import "GameScene.h"
#import "EnemyShip.h"

// To access some of Chipmunk's handy vector functions like cpvlerpconst().
#import "ObjectiveChipmunk/ObjectiveChipmunk.h"

// TODO
#import "CCPhysics+ObjectiveChipmunk.h"

@implementation PlayerShip
{
	CCNode *_mainThruster;
	id<ALSoundSource> _engineNoise;
	
	CCNode *_shield;

	// TODO: dynamic number of gunports based on ship. CCNode *_gunPort1, *_gunPort2;
	NSUInteger _currentGunPort;
	NSMutableArray *_gunPorts;
	
	float _speed;
	float _accelTime;
	int _hp;
}

-(void)didLoadFromCCB
{
	const float distortAmount = 0.25;
	
	_shieldDistortionSprite = [CCSprite spriteWithImageNamed:@"DistortionTexture.png"];
	_shieldDistortionSprite.opacity = distortAmount;
	
	// Rotate the distortion sprite to twist the space behind it.
	[_shieldDistortionSprite runAction:[CCActionRepeatForever actionWithAction:[CCActionRotateBy actionWithDuration:1.0 angle:-360.0]]];
}

static void
VisitAll(CCNode *node, void (^block)(CCNode *))
{
	block(node);
	for(CCNode *child in node.children) VisitAll(child, block);
}

-(void)onEnter
{
	CCPhysicsBody *body = self.physicsBody;
	
	// This is used to pick which collision delegate method to call, see GameScene.m for more info.
	body.collisionType = @"ship";
	
	// This sets up simple collision rules.
	// First you list the categories (strings) that the object belongs to.
	body.collisionCategories = @[CollisionCategoryPlayer];
	// Then you list which categories its allowed to collide with.
	body.collisionMask = @[CollisionCategoryEnemy, CollisionCategoryDebris, CollisionCategoryBarrier, CollisionCategoryPickup];
	
	// Make the thruster pulse
	float scaleX = _mainThruster.scaleX;
	float scaleY = _mainThruster.scaleY;
	[_mainThruster runAction:[CCActionRepeatForever actionWithAction:[CCActionSequence actions:
		[CCActionScaleTo actionWithDuration:0.1 scaleX:scaleX scaleY:0.5*scaleY],
		[CCActionScaleTo actionWithDuration:0.05 scaleX:scaleX scaleY:scaleY],
		nil
	]]];
	
	// Make the shield spin
	[_shield runAction:[CCActionRepeatForever actionWithAction:[CCActionRotateBy actionWithDuration:0.5 angle:360.0]]];
	
	_hp = 4;
	
	_gunPorts = [NSMutableArray array];
	VisitAll(self, ^(CCNode *node){
		if([node.name hasPrefix:@"gun"]){
			[_gunPorts addObject:node];
		}
	});
	
	[_gunPorts sortUsingComparator:^NSComparisonResult(CCNode *a, CCNode *b) {
		return [a.name compare:b.name];
	}];
	
	NSAssert([_gunPorts count] > 0, @"Missing gunports on ship in spritebuilder");
	
	
	[super onEnter];
}

-(void)onExit
{
	[_engineNoise stop];
	[_shieldDistortionSprite removeFromParent];
	
	[super onExit];
}

// This method is called from [GameScene fixedUpdate:], not from Cocos2D.
-(void)ggFixedUpdate:(CCTime)delta withControls:(Controls *)controls
{
	CCPhysicsBody *body = self.physicsBody;
	
	const float deadZone = 0.25;
	
	CGPoint thrust = controls.thrustDirection;
	if(cpvlength(thrust) > deadZone){
		float removeDeadZone = MAX(cpvlength(thrust) - deadZone, 0.0f)/(1.0 - deadZone);
		CGPoint targetVelocity = ccpMult(thrust, removeDeadZone*_speed);
		
		CGPoint velocity = cpvlerpconst(body.velocity, targetVelocity, _speed*delta/_accelTime);
		body.velocity = velocity;
		
		_mainThruster.visible = YES;
		
//		if(!_engineNoise){
//			_engineNoise = [[OALSimpleAudio sharedInstance] playEffect:@"Engine.wav" loop:YES];
//		}
//		
//		_engineNoise.volume = ccpLength(joystickValue);
	} else {
		_mainThruster.visible = NO;
//		[_engineNoise stop]; _engineNoise = nil;
	}
	
	// Mix some of the thrust control into the aiming to make it feel more dynamic.
	CGPoint aimDirection = ccpAdd(controls.aimDirection, ccpMult(thrust, 0.1));
	if(cpvlength(aimDirection) > 0.01){
		const float maxTurn = 360.0*delta;
		CGPoint relativeDirection = cpTransformVect(cpTransformInverse(body.absoluteTransform), aimDirection);
		self.rotation += clampf(-CC_RADIANS_TO_DEGREES(ccpToAngle(relativeDirection)), -maxTurn, maxTurn);
	}
	
	// Certain collisions can add to this. We want this to dampen off pretty quickly. (if not instantly)
	body.angularVelocity *= 0.9f;
}

-(void)update:(CCTime)delta
{
	_shieldDistortionSprite.position = self.position;
}

-(CGAffineTransform)gunPortTransform
{
	// Constantly switch between gunports.
	_currentGunPort = (_currentGunPort + 1) % [_gunPorts count];

	CCNode *gun = _gunPorts[_currentGunPort];
	
	return CGAffineTransformConcat(gun.nodeToWorldTransform, self.parent.worldToNodeTransform);
}

-(void)resetShield
{
	// TODO?
}

-(void)destroyShield
{
	float duration = 0.25;
	[_shield runAction:[CCActionSequence actions:
		[CCActionSpawn actions:
			[CCActionScaleTo actionWithDuration:duration scale:4.0],
			[CCActionFadeOut actionWithDuration:duration],
			nil
		],
		[CCActionHide action],
		nil
	]];
	
	_shieldDistortionSprite.visible = NO;
}

-(BOOL)takeDamage
{
	_hp -= 1;
	
	if(_hp == 1){
		[self destroyShield];
	}
		
	return _hp <= 0;
}

-(BOOL) isDead
{
	return _hp <= 0;
}

-(void)destroy
{
	CGPoint pos = self.position;
	GameScene *scene = (GameScene *)self.scene;
	
	CCNode *debris = [CCBReader load:self.debris];
	debris.position = pos;
	debris.rotation = self.rotation;
	InitDebris(debris, debris, self.physicsBody.velocity, [CCColor colorWithRed:1.0f green:1.0f blue:0.3f]);
	[self.parent addChild:debris z:Z_DEBRIS];
	
	CCNode *explosion = [CCBReader load:@"Particles/ShipExplosion"];
	explosion.position = pos;
	[self.parent addChild:explosion z:Z_PARTICLES];
	
	CCNode *distortion = [CCBReader load:@"DistortionParticles/LargeRing"];
	distortion.position = pos;
	[[scene distortionNode] addChild:distortion];
	
	[self scheduleBlock:^(CCTimer *timer) {
		[debris removeFromParent];
		[explosion removeFromParent];
		[distortion removeFromParent];
	} delay:5];
	
	for (EnemyShip * e in scene.enemies) {
		// explode based on distance from player.
		float dist = ccpLength(ccpSub(pos, e.position));
		[e scheduleBlock:^(CCTimer *timer) {[scene enemyDeath:e];} delay:dist / 200.0f];
	}
	
	[self removeFromParent];
}


@end