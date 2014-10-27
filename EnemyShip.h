//  Created by Andy Korth on 10/27/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface EnemyShip : CCNode

-(void)fixedUpdate:(CCTime)delta towardsPlayer:(CGPoint)playerPos;
-(void) dieNow;
-(BOOL) takeDamage;

@end