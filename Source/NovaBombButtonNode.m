//
//  NovaBombButtonNode.m
//  GalacticGuardian
//
//  Created by Viktor on 2/12/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "NovaBombButtonNode.h"

@interface NovaBombButtonNode ()
{
    int _numDisplayedBombs;
}
@end

@implementation NovaBombButtonNode

- (void) didLoadFromCCB
{
    self.glow.opacity = 0;
}

- (void) setNumBombs:(int)numBombs
{
    if (numBombs < 0) numBombs = 0;
    if (numBombs > 9) numBombs = 9;
    
    if (numBombs == _numDisplayedBombs) return;
    
    // Update number display
    if (numBombs)
    {
        CCSpriteFrame* digitFrame = [CCSpriteFrame frameWithImageNamed:[NSString stringWithFormat:@"UI/number_%d.png", numBombs]];
        [_digit setSpriteFrame:digitFrame];
        _digit.visible = YES;
    }
    else
    {
        _digit.visible = NO;
    }
    
    // Flash if we gained a bomb
    if (numBombs > _numDisplayedBombs)
    {
        [_glow runAction:[CCActionFadeOut actionWithDuration:1.0]];
    }
    
    _numDisplayedBombs = numBombs;
}

@end
