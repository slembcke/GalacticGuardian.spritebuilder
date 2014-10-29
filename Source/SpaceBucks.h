#import "CCSprite.h"
#import "Constants.h"
#import "PlayerShip.h"

@interface SpaceBucks : CCSprite

@property(nonatomic, assign) float accelRange;
@property(nonatomic, assign) float accelAmount;

@property(nonatomic, assign) int amount;

-(void)fixedUpdate:(CCTime)delta towardsPlayer:(PlayerShip *)player;


@end
