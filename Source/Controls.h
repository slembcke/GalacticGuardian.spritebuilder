typedef NS_ENUM(NSUInteger, ControlButton){
	ControlFireButton,
	ControlRocketButton,
	ControlNovaButton,
	ControlPauseButton,
};

typedef void (^ControlHandler)(BOOL state);


@interface Controls : CCNode

@property(nonatomic, assign) BOOL rocketButtonEnabled;
@property(nonatomic, assign) BOOL rocketButtonVisible;

@property(nonatomic, assign) BOOL novaButtonEnabled;
@property(nonatomic, assign) BOOL novaButtonVisible;

-(CGPoint)thrustDirection;
-(CGPoint)aimDirection;

-(BOOL)getButton:(ControlButton)button;
-(void)setHandler:(ControlHandler)block forButton:(ControlButton)button;

@end
