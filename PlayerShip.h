//
//  MyShip.h
//  GalacticGuardian
//
//  Created by Andy Korth on 10/27/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface PlayerShip : CCNode

@property(nonatomic, readonly) NSString *debris;

@property(nonatomic, readonly) CGAffineTransform gunPortTransform;

@property(nonatomic) float fireRate;
@property(nonatomic) float lastFireTime;

-(void)fixedUpdate:(CCTime)delta withInput:(CGPoint)joystickValue;

-(BOOL)takeDamage;

@end