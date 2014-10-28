#import "ObjectiveChipmunk/ObjectiveChipmunk.h"

#import "Controls.h"


static CGPoint DirectionValue = {0.0, 0.0};
static BOOL FireValue = NO;


@interface Joystick : CCNode @end
@implementation Joystick {
	CGPoint _center;
	float _radius;
	
	__unsafe_unretained CCTouch *_trackingTouch;
}

-(instancetype)initWithSize:(CGFloat)size
{
	if((self = [super init])){
		self.contentSize = CGSizeMake(size, size);
		self.anchorPoint = ccp(0.5, 0.5);
	}
	
	return self;
}

-(void)onEnter
{
	[super onEnter];
	
	_center = self.position;
	_radius = self.contentSize.width/2.0;
	
	// Quick and dirty way to draw the joystick nub.
	CCDrawNode *drawNode = [CCDrawNode node];
	[self addChild:drawNode];
	
	[drawNode drawDot:self.anchorPointInPoints radius:_radius color:[CCColor colorWithWhite:1.0 alpha:0.5]];
	
	self.userInteractionEnabled = YES;
}

-(void)setTouchPosition:(CGPoint)touch
{
	CGPoint delta = cpvclamp(cpvsub(touch, _center), _radius);
	self.position = cpvadd(_center, delta);
	
	DirectionValue = cpvmult(delta, 1.0/_radius);
}

-(void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
	if(_trackingTouch) return;
	
	CGPoint pos = [touch locationInNode:self.parent];
	if(cpvnear(_center, pos, _radius)){
		_trackingTouch = touch;
		self.touchPosition = pos;
	}
}

-(void)touchMoved:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
	if(touch == _trackingTouch){
		self.touchPosition = [touch locationInNode:self.parent];
	}
}

-(void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
	if(touch == _trackingTouch){
		_trackingTouch = nil;
		self.touchPosition = _center;
	}
}

-(void)touchCancelled:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
	[self touchEnded:touch withEvent:event];
}

@end


@implementation Controls

+(CCNode *)newControlsLayer
{
	CGSize viewSize = [CCDirector sharedDirector].viewSize;
	CCNode *node = [CCNode node];
	
	CGFloat joystickOffset = viewSize.width/8.0;
	CCNode *joystick = [[Joystick alloc] initWithSize:joystickOffset];
	joystick.position = ccp(joystickOffset, joystickOffset);
	[node addChild:joystick];
	
	return node;
}

+(CCNode *)gameControllerIndicator
{
	return nil;
}

+(CGPoint)directionValue {return DirectionValue;}
+(BOOL)fireValue {return FireValue;}

@end


//#import "GameController.h"
//
//
//@implementation GameController
//
//GCController *ControllerProfile;
//
//+(void)initialize
//{
//	[[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidConnectNotification object:nil queue:nil
//		usingBlock:^(NSNotification *notification){
//			ControllerProfile = notification.object;
//		}
//	];
//	
//	[[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidDisconnectNotification object:nil queue:nil
//		usingBlock:^(NSNotification *notification){
//			ControllerProfile = nil;
//		}
//	];
//}
//
//@end
