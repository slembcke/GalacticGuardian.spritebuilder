//
//  MadeWithSB.m
//  GalacticGuardian
//
//  Created by Viktor on 2/17/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "MadeWithSB.h"
#import "GameScene.h"
#import "BurnTransition.h"
#import "CCDirector_Private.h"

@implementation MadeWithSB

- (void) onEnterTransitionDidFinish
{
    [CCDirector sharedDirector].scheduler.timeScale = 1.0f;
    
    [self scheduleBlock:^(CCTimer *timer){
        // Restart the game after a short delay
        [[CCDirector sharedDirector] replaceScene:[[GameScene alloc] initWithShipType:Ship_Herald] withTransition:[BurnTransition burnTransitionWithDuration:1.0]];
    } delay:0.5f];
    
    [super onEnterTransitionDidFinish];
}

@end
