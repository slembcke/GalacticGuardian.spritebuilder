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

#import "Constants.h"
#import "GameScene.h"
#import "Rocket.h"


static const float RocketAcceleration = 1000.0;

static const float RocketDamage[] = {0.0, 14.0, 20.0, 10.0};
static const float RocketSplash = 150.0;

static const int RocketClusters = 3;
static const CCTime RocketClusterInterval = 0.2;
static const float RocketClusterRange = 25.0;


@implementation Rocket {
	RocketLevel _level;
}

+(instancetype)rocketWithLevel:(RocketLevel)level
{
	NSAssert(level != RocketNone, @"Not a valid rocket level.");
	
	Rocket *rocket = (Rocket *)[CCBReader load:@"Rocket"];
	rocket->_level = level;
	
	CGSize size = rocket.contentSize;
	CGFloat radius = size.height/2.0;
	
	CCPhysicsBody *body = rocket.physicsBody = [CCPhysicsBody bodyWithPillFrom:ccp(radius, radius) to:ccp(size.width - radius, radius) cornerRadius:radius];
	body.collisionType = @"rocket";
	body.collisionCategories = @[CollisionCategoryBullet];
	body.collisionMask = @[CollisionCategoryEnemy, CollisionCategoryAsteroid];
	
	CCTime fuse = sqrt(2.0*RocketRange/RocketAcceleration);
	[rocket scheduleBlock:^(CCTimer *timer) {
		[rocket destroy];
	} delay:fuse];
	
	return rocket;
}

-(void)fixedUpdate:(CCTime)delta
{
	CCPhysicsBody *body = self.physicsBody;
	CGAffineTransform transform = body.absoluteTransform;
	
	CGPoint direction = CGPointMake(transform.a, transform.b);
	body.velocity = ccpAdd(body.velocity, ccpMult(direction, RocketAcceleration*delta));
}

// Apply splash damage.
-(void)splashAt:(CGPoint)pos parent:(CCNode *)parent
{
	GameScene *scene = (GameScene *)parent.scene;
	[scene splashDamageAt:pos radius:RocketSplash damage:RocketDamage[_level]];
	
	CCNode *explosion = [CCBReader load:@"Particles/RocketExplosion"];
	explosion.position = pos;
	[parent addChild:explosion z:Z_FIRE];
	
	CCNode *smoke = [CCBReader load:@"Particles/Smoke"];
	smoke.position = pos;
	[parent addChild:smoke z:Z_SMOKE];
	
	CCNode *distortion = [CCBReader load:@"DistortionParticles/RocketRing"];
	distortion.position = pos;
	[scene.distortionNode addChild:distortion];
	
	[scene scheduleBlock:^(CCTimer *timer) {
		[explosion removeFromParent];
		[smoke removeFromParent];
		[distortion removeFromParent];
	} delay:2];
	
	[[OALSimpleAudio sharedInstance] playEffect:@"TempSounds/Explosion.wav" volume:2.0 pitch:1.0 pan:0.0 loop:NO];
}

-(void)destroy
{
	CCNode *parent = self.parent;
	CGPoint pos = self.position;
	
	[self splashAt:pos parent:parent];
	
	if(_level == RocketCluster){
		for(int i=1; i<RocketClusters; i++){
			[parent scheduleBlock:^(CCTimer *timer) {
				CGPoint splashPos = ccpAdd(pos, ccpMult(CCRANDOM_ON_UNIT_CIRCLE(), RocketClusterRange));
				[self splashAt:splashPos parent:parent];
			} delay:i*RocketClusterInterval];
		}
	}
	
	[self removeFromParent];
}

@end
