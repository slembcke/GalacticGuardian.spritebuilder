//
//  Joystick.m
//  Cocoroids
//
//  Created by Scott Lembcke on 1/20/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Joystick.h"
#import "ObjectiveChipmunk/ObjectiveChipmunk.h"


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
	
	CGPoint value = cpvmult(delta, 1.0/_radius);
	_value = (cpvnear(value, CGPointZero, _deadZone) ? CGPointZero : value);
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
