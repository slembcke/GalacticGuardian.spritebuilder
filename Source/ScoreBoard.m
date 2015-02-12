//
//  ScoreBoard.m
//  GalacticGuardian
//
//  Created by Viktor on 2/11/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "ScoreBoard.h"
#define NUM_DIGITS 8
#define DIGIT_SPACING 9.5
#define DIGIT_X 12
#define DIGIT_Y 12.5

@interface ScoreBoard()
{
    NSMutableArray* _digits;
}
@end

@implementation ScoreBoard

- (void) didLoadFromCCB
{
    _digits = [NSMutableArray array];
    for (int i = 0; i < NUM_DIGITS; i++)
    {
        CCSprite* digit = [CCSprite spriteWithImageNamed:@"UI/number_0.png"];
        digit.position = ccp(DIGIT_X + DIGIT_SPACING * i, DIGIT_Y);
        [self addChild:digit];
        [_digits addObject:digit];
    }
    
    [self updateScore];
}

- (void) setScore:(int)score
{
    if (score != _score)
    {
        _score = score;
        [self updateScore];
    }
}

- (void) updateScore
{
    NSString* scoreStr = [NSString stringWithFormat:@"% 8d",_score];
    for (int i = 0; i < NUM_DIGITS; i++)
    {
        CCSprite* digit = [_digits objectAtIndex:i];
        
        NSString* digitStr = [scoreStr substringWithRange:NSMakeRange(i, 1)];
        
        BOOL showDigit = ![digitStr isEqualToString:@" "];
        
        digit.visible = showDigit;
        
        if (showDigit)
        {
            CCSpriteFrame* digitFrame = [CCSpriteFrame frameWithImageNamed:[NSString stringWithFormat:@"UI/number_%@.png",digitStr]];
            digit.spriteFrame = digitFrame;
        }
    }
}

@end
