//
//  NovaBombButtonNode.h
//  GalacticGuardian
//
//  Created by Viktor on 2/12/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface NovaBombButtonNode : CCNode

@property (nonatomic,strong) CCSprite* glow;
@property (nonatomic,strong) CCSprite* digit;
@property (nonatomic,strong) CCButton* button;

- (void) setNumBombs:(int)numBombs;

@end
