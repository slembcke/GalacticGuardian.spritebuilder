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

#import "CCPhysics+ObjectiveChipmunk.h"

#import "SpaceBucks.h"
#import "PlayerShip.h"


@implementation SpaceBucks {
	__unsafe_unretained GameScene *_scene;
}

const int values[] = {1, 4, 8};

static NSArray *CollisionCategories = nil;
static NSArray *CollisionMask = nil;

+(void)initialize
{
	if(self != [SpaceBucks class]) return;
	
	CollisionCategories = @[CollisionCategoryPickup];
	CollisionMask = @[CollisionCategoryPlayer, CollisionCategoryEnemy, CollisionCategoryBarrier, CollisionCategoryPickup];
}

-(instancetype)initWithAmount:(SpaceBuckType) type
{
	if((self = [super initWithImageNamed:@"Sprites/gem.png"])){
		CGPoint center = self.anchorPointInPoints;
		CCPhysicsBody *body = self.physicsBody = [CCPhysicsBody bodyWithPillFrom:ccp(center.x, center.y - 1.0) to:ccp(center.x, center.y + 1.0) cornerRadius:1.5];
		body.mass = 0.01;
		
		_amount = values[type];
		_flashImage = @"Sprites/laserFlashGreen.png";
		
		// This is used to pick which collision delegate method to call, see GameScene.m for more info.
		body.collisionType = @"pickup";
		
		// This sets up simple collision rules.
		// First you list the categories (strings) that the object belongs to.
		body.collisionCategories = CollisionCategories;
		// Then you list which categories its allowed to collide with.
		body.collisionMask = CollisionMask;
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
		// Accelerate towards the player if they are nearby.
		float accel = AccelMin + AccelMax*(AccelRange - distance)/AccelRange;
		CGPoint direction = ccpNormalize(ccpSub(targetPoint, self.position));
		body.velocity = ccpAdd(body.velocity, ccpMult(direction, delta * accel));
	}
}

@end
