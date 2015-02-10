/*
 * Galactic Guardian
 *
 * Copyright (c) 2015 Scott Lembcke and Andy Korth
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "ObjectiveChipmunk/ObjectiveChipmunk.h"

#import "Controls.h"
#import "FancyJoystick.h"
#import "GameController.h"


#if GameControllerSupported
@interface Controls()<GameControllerDelegate> {
	GCExtendedGamepadSnapshot *_gamepad;
	
	GCControllerDirectionPad *_controllerStick;
	GCControllerDirectionPad *_controllerAim;
}

@end
#endif


@implementation Controls {
	FancyJoystick *_virtualJoystick;
	FancyJoystick *_virtualAimJoystick;
	
	CCButton *_novaButton;
	
	NSMutableDictionary *_buttonStates;
	NSMutableDictionary *_buttonHandlers;
	
	id _controllerConnectedObserver;
	id _controllerDisconnectedObserver;
}

-(id)init
{
	if((self = [super init])){
		CGSize viewSize = [CCDirector sharedDirector].viewSize;
		self.contentSizeType = CCSizeTypeNormalized;
		self.contentSize = CGSizeMake(1.0, 1.0);
		
		// Joystick offsets (and sizes) will be relative to actual screen size.
		CGFloat joystickOffset = (viewSize.width + viewSize.height) / 16.0;
		
		CCPositionType br =CCPositionTypeMake(CCPositionUnitPoints, CCPositionUnitPoints, CCPositionReferenceCornerBottomRight);
		CCPositionType bl =CCPositionTypeMake(CCPositionUnitPoints, CCPositionUnitPoints, CCPositionReferenceCornerBottomLeft);
		
		// _novaButton ivar is set by the CCB file, but wrapped in a regular node.
		CCNode *novaButtonNode = [CCBReader load:@"NovaButton" owner:self];
		novaButtonNode.positionType = br;
		novaButtonNode.position = ccp(2.0*joystickOffset, joystickOffset);
		novaButtonNode.contentSize = CGSizeMake(0.7*joystickOffset, 0.7*joystickOffset);
		[self addChild:novaButtonNode];
		
		// Exclusive touch would steal touches from the joysticks.
		_novaButton.exclusiveTouch = NO;
		
		_virtualJoystick = [FancyJoystick node];
		_virtualJoystick.scale = 2.0*joystickOffset/_virtualJoystick.contentSize.width;
		_virtualJoystick.positionType = bl;
		_virtualJoystick.position = ccp(joystickOffset, joystickOffset);
		[self addChild:_virtualJoystick];
		
		_virtualAimJoystick = [FancyJoystick node];
		_virtualAimJoystick.scale = 2.0*joystickOffset/_virtualJoystick.contentSize.width;
		_virtualAimJoystick.positionType = br;
		_virtualAimJoystick.position = ccp(joystickOffset, joystickOffset);
		[self addChild:_virtualAimJoystick];
		
		CCButton *pauseButton = [CCButton buttonWithTitle:@"Pause" fontName:@"kenvector_future.ttf" fontSize:18.0f];
		pauseButton.anchorPoint = ccp(1, 1);
		pauseButton.positionType = CCPositionTypeMake(CCPositionUnitPoints, CCPositionUnitPoints, CCPositionReferenceCornerTopRight);
		pauseButton.position = ccp(5, 5 + 30); // HUD is 30
		pauseButton.hitAreaExpansion = 2.0;
		[self addChild:pauseButton];
		
		__weak typeof(self) _self = self;
		pauseButton.block = ^(id sender){
			[_self callHandler:@(ControlPauseButton) value:YES];
		};
		
		_buttonStates = [NSMutableDictionary dictionary];
		_buttonHandlers = [NSMutableDictionary dictionary];
		
		self.userInteractionEnabled = YES;
	}
	
	return self;
}

#if GameControllerSupported
-(void)onEnterTransitionDidFinish
{
	[super onEnterTransitionDidFinish];
	
	[GameController addDelegate:self];
}

-(void)onExitTransitionDidStart
{
	[super onExitTransitionDidStart];
	
	[GameController removeDelegate:self];
}

-(void)pausePressed
{
	[self callHandler:@(ControlPauseButton) value:YES];
}

-(void)snapshotDidChange:(NSData *)snapshotData
{
	_gamepad.snapshotData = snapshotData;
}

-(void)controllerDidConnect
{
	_gamepad = [[GCExtendedGamepadSnapshot alloc] init];
	
	_controllerStick = _gamepad.leftThumbstick;
	_controllerAim = _gamepad.rightThumbstick;
	
	_gamepad.rightShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed){
		[self setButtonValue:ControlRocketButton value:pressed];
	};
	
	_gamepad.buttonA.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed){
		[self setButtonValue:ControlNovaButton value:pressed];
		
		_novaButton.highlighted = pressed;
	};
	
//	self.visible = NO;
}

-(void)controllerDidDisconnect
{
	_gamepad = nil;
	_controllerStick = nil;
	_controllerAim = nil;
	
//	self.visible = YES;
}
#endif

-(void)update:(CCTime)delta
{
#if GameControllerSupported
	CGPoint aim = CGPointZero;
	
	// If a controller is connected, read from that.
	// Otherwise read from the onscreen joystick.
	if(_controllerAim){
		aim = CGPointMake(_controllerAim.xAxis.value, _controllerAim.yAxis.value);
		_virtualAimJoystick.direction = aim;
	} else {
		aim = _virtualAimJoystick.direction;
	}
	
	if(_controllerStick){
		_virtualJoystick.direction = ccp(_controllerStick.xAxis.value, _controllerStick.yAxis.value);
	}
#else
	CGPoint aim = _virtualAimJoystick.direction;
#endif
	
	// Virtual fire button that is pressed when the aim joystick is used.
	[self setButtonValue:ControlFireButton value:(aim.x*aim.x + aim.y*aim.y) > 0.25];
}

-(void)setButtonValue:(ControlButton)button value:(BOOL)value
{
	NSNumber *key = @(button);
	BOOL prev = [_buttonStates[key] boolValue];
	
	if(value != prev){
		_buttonStates[key] = @(value);
		[self callHandler:key value:value];
	}
}

-(void)callHandler:(id)key value:(BOOL)value;
{
	if(self.isRunningInActiveScene){
		ControlHandler handler = _buttonHandlers[key];
		if(handler) handler(value);
	}
}

-(CGPoint)thrustDirection
{
#if GameControllerSupported
	if(_controllerStick){
		return cpvclamp(cpv(
			_controllerStick.xAxis.value,
			_controllerStick.yAxis.value
		), 1.0);
	} else {
		return _virtualJoystick.direction;
	}
#else
	return _virtualJoystick.direction;
#endif
}

-(CGPoint)aimDirection
{
#if GameControllerSupported
	if(_controllerAim){
		return cpvclamp(cpv(
			_controllerAim.xAxis.value,
			_controllerAim.yAxis.value
		), 1.0);
	} else {
		return _virtualAimJoystick.direction;
	}
#else
	return _virtualAimJoystick.direction;
#endif
}

-(BOOL)getButton:(ControlButton)button
{
	return [_buttonStates[@(button)] boolValue];
}

-(void)setHandler:(ControlHandler)block forButton:(ControlButton)button
{
	_buttonHandlers[@(button)] = block;
}

-(void)fireRocket:(CCButton *)sender
{
	// Kind of a hack since CCButton doesn't support continuous events. (yet?)
	[self setButtonValue:ControlRocketButton value:YES];
	[self setButtonValue:ControlRocketButton value:NO];
}

-(void)fireNova:(CCButton *)sender
{
	[self setButtonValue:ControlNovaButton value:YES];
	[self setButtonValue:ControlNovaButton value:NO];
}

-(BOOL)novaButtonEnabled {return _novaButton.enabled;}
-(void)setNovaButtonEnabled:(BOOL)novaButtonEnabled {_novaButton.enabled = novaButtonEnabled;}
-(BOOL)novaButtonVisible {return _novaButton.parent.visible;}
-(void)setNovaButtonVisible:(BOOL)novaButtonVisible {_novaButton.parent.visible = novaButtonVisible;}

@end
