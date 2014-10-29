@interface NebulaBackground : CCSprite

+(NSString *)toggleDistortionMode;

@property(nonatomic, readonly) CCNode *distortionNode;

@end
