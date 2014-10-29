typedef NS_ENUM(NSUInteger, ControlButton){
	ControlFireButton,
	ControlPauseButton,
};

typedef void (^ControlHandler)(BOOL state);

@interface Controls : CCNode

-(CGPoint)directionValue;

-(BOOL)getButton:(ControlButton)button;
-(void)setHandler:(ControlHandler)block forButton:(ControlButton)button;

@end
