//  Created by Andy Korth on 10/27/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "PlayerShip.h"
#import "GameScene.h"


@interface EnemyShip : CCNode

@property(nonatomic) int hp;
@property(nonatomic, readonly) NSString *debris;

-(BOOL) takeDamage:(int)damage;

-(void)destroyWithWeaponColor:(CCColor *)weaponColor;

@end