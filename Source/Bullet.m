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

#import "Constants.h"
#import "Bullet.h"
#import "GameScene.h"


static NSString * const bulletImageNames[] = {
	@"Sprites/laserBlue.png",
	@"Sprites/laserPurple.png",
	@"Sprites/laserGreen.png",
	@"Sprites/laserYellow.png",
	@"Sprites/laserRed.png",
	@"Sprites/laserPurple.png",
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
	200, 225, 400, 450, 500, 550
};
const float bulletDurations[] = {
	0.5, 0.52, 0.25, 0.30, 0.35, 0.40
};


@implementation Bullet

static NSArray *CollisionCategories = nil;
static NSArray *CollisionMask = nil;

// Cache some of these values when the class is loaded to avoid recreating them constantly.
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
		[CCColor colorWithRed:0.6f green:0.3f blue:1.0f],
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
    return NULL;
	//return bulletFlashes[_bulletLevel];
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
