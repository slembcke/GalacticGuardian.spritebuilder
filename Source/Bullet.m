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


static NSString * const bulletImageNames[] = {
	@"Sprites/laserBlue.png",
    @"Sprites/laserPurple.png",
	@"Sprites/laserGreen.png",
    @"Sprites/laserYellow.png",
	@"Sprites/laserRed.png",
	@"Sprites/laserRed.png",
};
static NSString * const bulletFlashes[] ={
    @"Sprites/laserFlashBlue.png",
    @"Sprites/laserFlashPurple.png",
    @"Sprites/laserFlashGreen.png",
    @"Sprites/laserFlashYellow.png",
    @"Sprites/laserFlashRed.png",
    @"Sprites/laserFlashRed.png",
};
static NSArray * bulletColors;

const float bulletSpeeds[] = {
	200, 225, 250, 225, 260, 275
};
const float bulletDurations[] = {
	0.5, 0.52, 0.54, 0.64, 0.66, 0.8
};


@implementation Bullet

static NSArray *CollisionCategories = nil;
static NSArray *CollisionMask = nil;

+(void)initialize
{
	if(self != [Bullet class]) return;
	
	CollisionCategories = @[CollisionCategoryBullet];
	CollisionMask = @[CollisionCategoryEnemy, CollisionCategoryAsteroid];
    
    bulletColors = @[
        [CCColor colorWithRed:0.2f green:0.7f blue:1.0f],
        [CCColor colorWithRed:0.6f green:0.3f blue:1.0f],
        [CCColor colorWithRed:0.2f green:1.0f blue:0.4f],
        [CCColor colorWithRed:0.95f green:0.8f blue:0.15f],
        [CCColor colorWithRed:1.0f green:0.2f blue:0.2f],
        [CCColor colorWithRed:1.0f green:0.2f blue:0.2f],
    ];
}

-(instancetype)initWithBulletLevel:(BulletLevel) level
{
	if((self = [super initWithImageNamed:bulletImageNames[level] ])){
		_bulletLevel = level;
		CGSize size = self.contentSize;
		CGFloat radius = size.width/2.0;
		
		CCPhysicsBody *body = self.physicsBody = [CCPhysicsBody bodyWithPillFrom:ccp(radius, radius) to:ccp(radius, size.height - radius) cornerRadius:radius];
		
		// This is used to pick which collision delegate method to call, see GameScene.m for more info.
		body.collisionType = @"bullet";
		
		// This sets up simple collision rules.
		// First you list the categories (strings) that the object belongs to.
		body.collisionCategories = CollisionCategories;
		// Then you list which categories its allowed to collide with.
		body.collisionMask = CollisionMask;
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
	return bulletSpeeds[_bulletLevel];
}

-(float)duration
{
	return bulletDurations[_bulletLevel];
}

-(NSString *)flashImagePath
{
	return bulletFlashes[_bulletLevel];
}

-(CCColor *)bulletColor
{
    return bulletColors[_bulletLevel];
}

-(void)destroy
{
	// Draw a little flash at it's last position
	[(GameScene *)self.scene drawBulletFlash:self];
	[self removeFromParent];
}

@end
