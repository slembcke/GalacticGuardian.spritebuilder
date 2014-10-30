typedef NS_ENUM(NSUInteger, RocketLevel){
	RocketSmall, RocketLarge, RocketCluster,
};

@interface Rocket : CCNode

+(instancetype)rocketWithLevel:(RocketLevel)level;

-(void)destroy;

@end
