//
//  MyShip.h
//  GalacticGuardian
//
//  Created by Andy Korth on 10/27/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

#import "Controls.h"


@interface PlayerShip : CCNode

@property(nonatomic, readonly) NSString *debris;

@property(nonatomic, readonly) CGAffineTransform gunPortTransform;

@property(nonatomic) float fireRate;
@property(nonatomic) float lastFireTime;

@property(nonatomic) CCSprite *shieldDistortionSprite;

-(void)ggFixedUpdate:(CCTime)delta withControls:(Controls *)controls;

-(BOOL)takeDamage;
-(BOOL)isDead;

-(void)destroy;

@end