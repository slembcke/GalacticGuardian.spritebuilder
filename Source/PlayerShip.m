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

-(void)onEnter
{
	CCPhysicsBody *body = self.physicsBody;
	
	// This is used to pick which collision delegate method to call, see GameScene.m for more info.
	body.collisionType = @"ship";
	
	// This sets up simple collision rules.
	// First you list the categories (strings) that the object belongs to.
	body.collisionCategories = @[CollisionCategoryPlayer];
	// Then you list which categories its allowed to collide with.
	body.collisionMask = @[CollisionCategoryEnemy, CollisionCategoryDebris, CollisionCategoryBarrier];
	
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
	for (CCNode* node in [_children[0] children]) {
		if([node.name isEqualToString:@"gun"]){
			[_gunPorts addObject:node];
		}
	}
	NSAssert([_gunPorts count] > 0, @"Missing gunports on ship in spritebuilder");
	
	
	[super onEnter];
}

-(void)onExit
{
	[_engineNoise stop];
	
	[super onExit];
}

// This method is called from [GameScene fixedUpdate:], not from Cocos2D.
-(void)fixedUpdate:(CCTime)delta withInput:(CGPoint)joystickValue
{
	CCPhysicsBody *body = self.physicsBody;

	//	CCLOG(@"velocity: %@", NSStringFromCGPoint(velocity));
	if(cpvlengthsq(joystickValue)){
		const float maxTurn = 360.0*delta;
		CGPoint relativeDirection = cpTransformVect(cpTransformInverse(body.body.transform), joystickValue);
		self.rotation += clampf(-CC_RADIANS_TO_DEGREES(ccpToAngle(relativeDirection)), -maxTurn, maxTurn);
		
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

	float newSpeed = (cpfclamp(cpvlength(joystickValue) - 0.5f, 0.0f, 0.5f)) * 2.0f * _speed;
	CGPoint targetVelocity = ccpMult(joystickValue, newSpeed);
	
	CGPoint velocity = cpvlerpconst(body.velocity, targetVelocity, newSpeed/_accelTime*delta);
	body.velocity = velocity;

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
	
	// Why not just position multiply the gun transform by the _transform? Guns are flipped with negative scales, so we need to explictly ignore that.
	// So instead, we just offset from the ship's translation. 
	return CGAffineTransformTranslate(_transform, -gun.position.y, gun.position.x);
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


@end