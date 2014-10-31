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
	@"Sprites/Bullets/laserBlue02.png",
	@"Sprites/Bullets/laserGreen04.png",
	@"Sprites/Bullets/laserRed02.png",
	@"Sprites/Bullets/laserBlue14.png",
	@"Sprites/Bullets/laserGreen06.png",
	@"Sprites/Bullets/laserRed14.png",
};
static NSString * const bulletFlashes[] ={
	@"Sprites/Bullets/laserBlue08.png",
	@"Sprites/Bullets/laserGreen14.png",
	@"Sprites/Bullets/laserRed08.png",
	@"Sprites/Bullets/laserBlue08.png",
	@"Sprites/Bullets/laserGreen14.png",
	@"Sprites/Bullets/laserRed08.png"};

const float bulletSpeeds[] = {
	200, 225, 250, 225, 260, 295
};
const float bulletDurations[] = {
	0.5, 0.52, 0.54, 0.64, 0.66, 0.70
};


@implementation Bullet

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
	if(_bulletLevel % 3 == 0){
		return 	[CCColor colorWithRed:0.3f green:0.8f blue:1.0f];
	}else if(_bulletLevel % 3 == 1){
		return 	[CCColor colorWithRed:0.3f green:1.0f blue:0.5f];
	}else{
		return 	[CCColor colorWithRed:1.0f green:0.2f blue:0.2f];
	}
}


-(void)destroy
{
	// Draw a little flash at it's last position
	[(GameScene *)self.scene drawBulletFlash:self];
	[self removeFromParent];
}

@end
