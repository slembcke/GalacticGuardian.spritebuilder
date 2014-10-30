//
//  Bullet.m
//  Cocoroids
//
//  Created by Scott Lembcke on 1/20/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Constants.h"

#import "Bullet.h"

#import "GameScene.h"

@implementation Bullet

-(instancetype)initWithTMP
{
	if((self = [super initWithImageNamed:@"Sprites/Bullets/laserBlue12.png"])){
		CGSize size = self.contentSize;
		CGFloat radius = size.width/2.0;
		
		CCPhysicsBody *body = self.physicsBody = [CCPhysicsBody bodyWithPillFrom:ccp(radius, radius) to:ccp(radius, size.height - radius) cornerRadius:radius];
		
		// This is used to pick which collision delegate method to call, see GameScene.m for more info.
		body.collisionType = @"bullet";
		
		// This sets up simple collision rules.
		// First you list the categories (strings) that the object belongs to.
		body.collisionCategories = @[CollisionCategoryBullet];
		// Then you list which categories its allowed to collide with.
		body.collisionMask = @[CollisionCategoryEnemy, CollisionCategoryAsteroid];
	}
	
	return self;
}

-(void)onEnter
{
	[self scheduleBlock:^(CCTimer *timer){[self destroy];} delay:self.duration];
	
	[super onEnter];
}

-(float)speed
{
	return 500.0;
}

-(float)duration
{
	return 0.25;
}

-(void)destroy
{
	// Draw a little flash at it's last position
	[(GameScene *)self.scene drawFlash:self.position];
	
//	// Draw a little distortion too
//	CCSprite *distortion = [CCSprite spriteWithImageNamed:@"DistortionTexture.png"];
//	distortion.position = pos;
//	distortion.scale = 0.25;
//	[[(GameScene *)self.scene distortionNode] addChild:distortion];
//	
//	[distortion runAction:[CCActionSequence actions:
//		[CCActionSpawn actions:
//			[CCActionFadeOut actionWithDuration:duration],
//			[CCActionScaleTo actionWithDuration:duration scale:1.0],
//			nil
//		],
//		[CCActionRemove action],
//		nil
//	]];
	
	// Make some noise. Add a little chromatically tuned pitch bending to make it more musical.
//	int half_steps = (arc4random()%(2*4 + 1) - 4);
//	float pitch = pow(2.0f, half_steps/12.0f);
//	[[OALSimpleAudio sharedInstance] playEffect:@"Fizzle.wav" volume:1.0 pitch:pitch pan:0.0 loop:NO];
	
	[self removeFromParent];
}

@end
