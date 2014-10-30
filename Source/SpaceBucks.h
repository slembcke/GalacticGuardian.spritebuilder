#import "CCSprite.h"
#import "Constants.h"
#import "PlayerShip.h"
#import "GameScene.h"


typedef NS_ENUM(NSUInteger, SpaceBuckType){
	SpaceBuck_1, SpaceBuck_4, SpaceBuck_8
};


@interface SpaceBucks : CCSprite

@property(nonatomic, assign) int amount;
@property(nonatomic, assign) NSString *flashImage;

-(instancetype)initWithAmount:(SpaceBuckType) type;
-(void)ggFixedUpdate:(CCTime)delta scene:(GameScene *)scene;

@end
