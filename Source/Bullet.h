//
//  Bullet.h
//  Cocoroids
//
//  Created by Scott Lembcke on 1/20/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCSprite.h"

typedef NS_ENUM(NSUInteger, BulletLevel){
	BulletBlue1, BulletBlue2, BulletGreen1, BulletGreen2, BulletRed1, BulletRed2
};

@interface Bullet : CCSprite

@property(nonatomic, readonly) float speed;
@property(nonatomic, readonly) float duration;
@property(nonatomic, readonly) NSString *flashImagePath;
@property(nonatomic, readonly) BulletLevel bulletLevel;
@property(nonatomic, readonly) CCColor *bulletColor;

-(instancetype)initWithBulletLevel:(BulletLevel) level;

-(void)destroy;

@end

