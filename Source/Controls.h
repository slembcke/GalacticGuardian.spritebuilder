typedef NS_ENUM(NSUInteger, ControlButton){
	ControlFireButton,
	ControlRocketButton,
	ControlPauseButton,
};

typedef void (^ControlHandler)(BOOL state);

@interface Controls : CCNode

-(CGPoint)thrustDirection;
-(CGPoint)aimDirection;

-(BOOL)getButton:(ControlButton)button;
-(void)setHandler:(ControlHandler)block forButton:(ControlButton)button;

@end
