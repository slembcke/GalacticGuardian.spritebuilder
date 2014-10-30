//
//  Bullet.h
//  Cocoroids
//
//  Created by Scott Lembcke on 1/20/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCSprite.h"

@interface Bullet : CCSprite

@property(nonatomic, readonly) float speed;
@property(nonatomic, readonly) float duration;
@property(nonatomic, readonly) NSString *flashImagePath;


-(instancetype)initWithTMP;

-(void)destroy;

@end
