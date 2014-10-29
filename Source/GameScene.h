@interface GameScene : CCScene<CCPhysicsCollisionDelegate>

-(instancetype)initWithShipType:(NSString *)shipType level:(int) shipLevel;

@end
