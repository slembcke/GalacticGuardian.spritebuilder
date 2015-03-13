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

#import "Constants.h"

#import "PlayerShip.h"
#import "GameScene.h"
#import "EnemyShip.h"

// To access some of Chipmunk's handy vector functions like cpvlerpconst().
#import "ObjectiveChipmunk/ObjectiveChipmunk.h"

#import "CCPhysics+ObjectiveChipmunk.h"

@implementation PlayerShip
{
	CCNode *_mainThruster;
	id<ALSoundSource> _engineNoise;
	
	CCSprite *_shield;
	CCLightNode *_shieldLight;
	CCLightNode *_bulletLight;
	
	NSUInteger _currentGunPort;
	NSMutableArray *_gunPorts;
	
	float _speed;
	float _accelTime;
	int _hp;
	int _maxHP;
}

-(void)didLoadFromCCB
{
	const float distortAmount = 0.25;
	
	// Set up the distortion effect for the shield.
	// This will be added to the distortion field effect when the ship is added to the game.
	_shieldDistortionSprite = [CCSprite spriteWithImageNamed:@"DistortionTexture.png"];
	_shieldDistortionSprite.opacity = distortAmount;
	
	// Rotate the distortion sprite to twist the space behind it.
	[_shieldDistortionSprite runAction:[CCActionRepeatForever actionWithAction:[CCActionRotateBy actionWithDuration:1.0 angle:-360.0]]];
	
	_maxHP = _hp;
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

// This method is called from [GameScene fixedUpdate:], not directly from Cocos2D.
// I use a bunch of Chipmunk math functions in here since it's a bit more complete than Cocos's.
-(void)ggFixedUpdate:(CCTime)delta withControls:(Controls *)controls index:(NSUInteger)index
{
	CCPhysicsBody *body = self.physicsBody;
	
	const float deadZone = 0.25;
	
	CGPoint thrust = (index == 0 ? controls.thrustDirection1 : controls.thrustDirection2);
	if(cpvlength(thrust) > deadZone){
		float removeDeadZone = MAX(cpvlength(thrust) - deadZone, 0.0f)/(1.0 - deadZone);
		CGPoint desiredVelocity = ccpMult(thrust, removeDeadZone*_speed);
		
		// Accelerate the ship towards the desired velocity.
		CGPoint velocity = cpvlerpconst(body.velocity, desiredVelocity, _speed*delta/_accelTime);
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
	CGPoint aim = (index == 0 ? controls.aimDirection1 : controls.aimDirection2);
	CGPoint aimDirection = ccpAdd(aim, ccpMult(thrust, 0.1));
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
	// The distortion sprite is not a child of the ship so we have to sync their positions manually.
	_shieldDistortionSprite.position = self.position;
	
	float decay = 10.0*delta;
	_bulletLight.intensity = _bulletLight.specularIntensity = cpflerpconst(_bulletLight.intensity, 0.0f, decay);
}

-(void)bulletFlash:(CCColor *)color
{
	_bulletLight.color = color;
	_bulletLight.intensity = _bulletLight.specularIntensity = 2.0;
}

-(CGAffineTransform)gunPortTransform
{
	// Switch to a different gunport each time it's fired.
	_currentGunPort = (_currentGunPort + 1) % [_gunPorts count];

	CCNode *gun = _gunPorts[_currentGunPort];
	
	return CGAffineTransformConcat(gun.nodeToWorldTransform, self.parent.worldToNodeTransform);
}

-(void)resetShield
{
	// TODO?
}

-(void)flashShield
{
	CCSprite *sprite = [CCSprite spriteWithSpriteFrame:_shield.spriteFrame];
	sprite.position = _shield.position;
	sprite.rotation = _shield.rotation;
	[_shield.parent addChild:sprite];
	
	float duration = 0.25;
	[sprite runAction:[CCActionSequence actions:
		[CCActionSpawn actions:
			[CCActionScaleTo actionWithDuration:duration scale:4.0],
			[CCActionFadeOut actionWithDuration:duration],
			nil
		],
		[CCActionRemove action],
		nil
	]];
	
}

-(BOOL)takeDamage
{
	_hp -= 1;
	
	[self flashShield];
	
	if(_hp == 1){
		_shield.visible = NO;
		_shieldLight.intensity = 0.0;
		_shieldDistortionSprite.visible = NO;
	}
		
	return _hp <= 0;
}

-(BOOL) isDead
{
	return _hp <= 0;
}

-(float)health
{
	return (float)(_hp - 1.0)/(float)(_maxHP - 1.0);
}

-(void)destroy
{
	CGPoint pos = self.position;
	GameScene *scene = (GameScene *)self.scene;
	
	// Spawn some debris pieces.
	CCNode *debris = [CCBReader load:self.debris];
	debris.position = pos;
	debris.rotation = self.rotation;
	InitDebris(debris, debris, self.physicsBody.velocity, [CCColor colorWithRed:1.0f green:1.0f blue:0.3f]);
	[self.parent addChild:debris z:Z_DEBRIS];
	
	// Add explosion and smoke particles.
	CCNode *explosion = [CCBReader load:@"Particles/ShipExplosion"];
	explosion.position = pos;
	[self.parent addChild:explosion z:Z_FIRE];
	
	CCNode *smoke = [CCBReader load:@"Particles/Smoke"];
	smoke.position = pos;
	[self.parent addChild:smoke z:Z_SMOKE];
	
	[self scheduleBlock:^(CCTimer *timer) {
		[debris removeFromParent];
		[explosion removeFromParent];
		[smoke removeFromParent];
	} delay:5];
	
	// For dramatic effect. Killing the player sets off a nova explosion.
	[scene novaBombAt:pos];
	[[OALSimpleAudio sharedInstance] playEffect:@"TempSounds/Explosion.wav" volume:2.0 pitch:scene.pitchScale pan:0.0 loop:NO];
	
	[self removeFromParent];
}


@end