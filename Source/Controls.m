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
#import "NovaBombButtonNode.h"


#if GameControllerSupported
@interface Controls()<GameControllerDelegate> {
	GCExtendedGamepadSnapshot *_gamepad1;
	GCControllerDirectionPad *_controllerStick1;
	GCControllerDirectionPad *_controllerAim1;
	
	GCExtendedGamepadSnapshot *_gamepad2;
	GCControllerDirectionPad *_controllerStick2;
	GCControllerDirectionPad *_controllerAim2;
}

@end
#endif


@implementation Controls {
	FancyJoystick *_virtualJoystick;
	FancyJoystick *_virtualAimJoystick;
	
	//CCButton *_novaButton;
    NovaBombButtonNode* _novaButtonNode;
	
	NSMutableDictionary *_buttonStates;
	NSMutableDictionary *_buttonHandlers;
	
	id _controllerConnectedObserver;
	id _controllerDisconnectedObserver;
}

-(id)init
{
	if((self = [super init])){
        
		self.contentSizeType = CCSizeTypeNormalized;
		self.contentSize = CGSizeMake(1.0, 1.0);
		
		// Joystick offsets (and sizes) will be relative to actual screen size.
        CGFloat joystickOffset = 52;
        CGFloat novaButtonOffset = 128;
        CGFloat joystickScale = 0.6;
		
		CCPositionType br =CCPositionTypeMake(CCPositionUnitPoints, CCPositionUnitPoints, CCPositionReferenceCornerBottomRight);
		CCPositionType bl =CCPositionTypeMake(CCPositionUnitPoints, CCPositionUnitPoints, CCPositionReferenceCornerBottomLeft);
		
		// _novaButton ivar is set by the CCB file, but wrapped in a regular node.
		_novaButtonNode = (NovaBombButtonNode*)[CCBReader load:@"NovaButton" owner:self];
		_novaButtonNode.positionType = br;
		_novaButtonNode.position = ccp(novaButtonOffset, joystickOffset);
        _novaButtonNode.scale = joystickScale * 2;
		[self addChild:_novaButtonNode];
		
		// Exclusive touch would steal touches from the joysticks.
        _novaButtonNode.button.exclusiveTouch = NO;
		
		_virtualJoystick = [FancyJoystick node];
        _virtualJoystick.scale = joystickScale;
		_virtualJoystick.positionType = bl;
		_virtualJoystick.position = ccp(joystickOffset, joystickOffset);
		[self addChild:_virtualJoystick];
		
		_virtualAimJoystick = [FancyJoystick node];
        _virtualAimJoystick.scale = joystickScale;
		_virtualAimJoystick.positionType = br;
		_virtualAimJoystick.position = ccp(joystickOffset, joystickOffset);
		[self addChild:_virtualAimJoystick];
		
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

-(void)pausePressed:(NSUInteger)index
{
	[self callHandler:@(ControlPauseButton) value:YES];
}

-(void)snapshotDidChange:(NSData *)snapshotData index:(NSUInteger)index
{
	NSAssert(index < 2, @"Uh... 3 players?");
	
	if(index == 0){
		_gamepad1.snapshotData = snapshotData;
	} else {
		_gamepad2.snapshotData = snapshotData;
	}
}

-(void)controllerDidConnect:(NSUInteger)index
{
	NSAssert(index < 2, @"Uh... 3 players?");
	
	if(index == 0){
		_gamepad1 = [[GCExtendedGamepadSnapshot alloc] init];
		
		_controllerStick1 = _gamepad1.leftThumbstick;
		_controllerAim1 = _gamepad1.rightThumbstick;
		
		_gamepad1.buttonA.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed){
			[self setButtonValue:ControlNovaButton value:pressed];
			
			_novaButtonNode.button.highlighted = pressed;
		};
	} else {
		_gamepad2 = [[GCExtendedGamepadSnapshot alloc] init];
		
		_controllerStick2 = _gamepad2.leftThumbstick;
		_controllerAim2 = _gamepad2.rightThumbstick;
		
		_gamepad2.buttonA.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed){
			[self setButtonValue:ControlNovaButton value:pressed];
			
			_novaButtonNode.button.highlighted = pressed;
		};
	}
}

-(void)controllerDidDisconnect:(NSUInteger)index
{
	NSAssert(index < 2, @"Uh... 3 players?");
	
	if(index == 0){
		_gamepad1 = nil;
		_controllerStick1 = nil;
		_controllerAim1 = nil;
	} else {
		_gamepad2 = nil;
		_controllerStick2 = nil;
		_controllerAim2 = nil;
	}
	
//	self.visible = YES;
}
#endif

-(void)update:(CCTime)delta
{
#if GameControllerSupported
	CGPoint aim = CGPointZero;
	
	// If a controller is connected, read from that.
	// Otherwise read from the onscreen joystick.
	if(_controllerAim1){
		aim = CGPointMake(_controllerAim1.xAxis.value, _controllerAim1.yAxis.value);
		_virtualAimJoystick.direction = aim;
	} else {
		aim = _virtualAimJoystick.direction;
	}
	
	if(_controllerStick1){
		_virtualJoystick.direction = ccp(_controllerStick1.xAxis.value, _controllerStick1.yAxis.value);
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

-(CGPoint)thrustDirection1
{
	return cpvclamp(cpv(
		_controllerStick1.xAxis.value,
		_controllerStick1.yAxis.value
	), 1.0);
}

-(CGPoint)aimDirection1
{
	return cpvclamp(cpv(
		_controllerAim1.xAxis.value,
		_controllerAim1.yAxis.value
	), 1.0);
}

-(CGPoint)thrustDirection2
{
	return cpvclamp(cpv(
		_controllerStick2.xAxis.value,
		_controllerStick2.yAxis.value
	), 1.0);
}

-(CGPoint)aimDirection2
{
	return cpvclamp(cpv(
		_controllerAim2.xAxis.value,
		_controllerAim2.yAxis.value
	), 1.0);
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

- (void) setNovaBombs:(int)bombs
{
    [_novaButtonNode setNumBombs:bombs];
    
    _novaButtonNode.button.enabled = (bombs > 0);
}

@end
