//
//  MyShip.h
//  GalacticGuardian
//
//  Created by Andy Korth on 10/27/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface MyShip : CCNode

@property(nonatomic, readonly) CGAffineTransform gunPortTransform;

-(void)fixedUpdate:(CCTime)delta withInput:(CGPoint)joystickValue;

-(BOOL)takeDamage;

@end