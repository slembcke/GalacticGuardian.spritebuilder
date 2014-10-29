//  Created by Andy Korth on 10/27/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"
#import "PlayerShip.h"

@interface EnemyShip : CCNode

@property(nonatomic, readonly) NSString *debris;

-(void)fixedUpdate:(CCTime)delta towardsPlayer:(PlayerShip *)player;
-(BOOL) takeDamage;

@end