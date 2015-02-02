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

#if !ANDROID
#import "CCController.h"
#endif

#import "ObjectiveChipmunk/ObjectiveChipmunk.h"

#import "Controls.h"
#import "FancyJoystick.h"


@implementation Controls {
	FancyJoystick *_virtualJoystick;
	FancyJoystick *_virtualAimJoystick;
	
	CCButton *_rocketButton;
	CCButton *_novaButton;
	
#if !ANDROID
	GCController *_controller;
	GCControllerDirectionPad *_controllerStick;
	GCControllerDirectionPad *_controllerAim;
#endif
	
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
        
		// _rocketButton ivar is set by the CCB file, but wrapped in a regular node.
		CCNode *rocketButtonNode = [CCBReader load:@"RocketButton" owner:self];
		rocketButtonNode.positionType = bl;
		rocketButtonNode.position = ccp(2.0*joystickOffset, joystickOffset);
		rocketButtonNode.contentSize = CGSizeMake(0.7*joystickOffset, 0.7*joystickOffset);
		[((CCButton*) rocketButtonNode.children[0]).background setMargin: 0.0f];
		[self addChild:rocketButtonNode];
		
		// _novaButton ivar is set by the CCB file, but wrapped in a regular node.
		CCNode *novaButtonNode = [CCBReader load:@"NovaButton" owner:self];
		novaButtonNode.positionType = br;
		novaButtonNode.position = ccp(2.0*joystickOffset, joystickOffset);
		novaButtonNode.contentSize = CGSizeMake(0.7*joystickOffset, 0.7*joystickOffset);
		[self addChild:novaButtonNode];
		
		// Exclusive touch would steal touches from the joysticks.
		_rocketButton.exclusiveTouch = NO;
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
		
#if !ANDROID
		[self setupGamepadSupport];
#endif
	}
	
	return self;
}

#if !ANDROID
-(void)logController:(GCController *)controller
{
	NSLog(@"Controller: %@", controller);
	NSLog(@"	Extended: %@", controller.extendedGamepad);
	NSLog(@"	VendorName: %@", controller.vendorName);
}

-(BOOL)activateController:(GCController *)controller
{
	if(_controller || controller.extendedGamepad == nil) return NO;
	
	NSLog(@"Using controller %@", controller);
	_controller = controller;
	controller.playerIndex = 0;
	
	_controllerStick = controller.extendedGamepad.leftThumbstick;
	_controllerAim = controller.extendedGamepad.rightThumbstick;
	
	__weak typeof(self) _self = self;
	
	controller.extendedGamepad.rightShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed){
		[_self setButtonValue:ControlRocketButton value:pressed];
	};
	
	controller.extendedGamepad.buttonA.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed){
		[_self setButtonValue:ControlNovaButton value:pressed];
	};
	
	controller.controllerPausedHandler = ^(GCController *controller){
		[_self callHandler:@(ControlPauseButton) value:YES];
	};
	
	_controllerDisconnectedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidDisconnectNotification object:controller queue:nil
		usingBlock:^(NSNotification *notification){
			NSLog(@"Controller disconnected.");
			
			GCController *controller = notification.object;
			[_self logController:controller];
			[_self deactivateController:controller];
		}
	];
	
	self.visible = NO;
	return YES;
}

-(void)deactivateController:(GCController *)controller
{
	if(controller == nil) return;
	
	NSAssert(controller == _controller, @"Deactivating some other controller!?");
	
	_controller.extendedGamepad.rightShoulder.valueChangedHandler = nil;
	_controller.controllerPausedHandler = nil;
	
	_controller = nil;
	_controllerStick = nil;
	_controllerAim = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:_controllerDisconnectedObserver];
	_controllerDisconnectedObserver = nil;
	
	self.visible = YES;
}

-(void)setupGamepadSupport
{
	if(NSClassFromString(@"GCController") == nil) return;

	NSArray *controllers = [CCController controllers];
	NSLog(@"%d controllers found.", (int)controllers.count);
	
	for(GCController *controller in controllers){
		[self logController:controller];
		if(_controller == nil) [self activateController:controller];
	}
	
	__weak typeof(self) _self = self;
	_controllerConnectedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidConnectNotification object:nil queue:nil
		usingBlock:^(NSNotification *notification){
			NSLog(@"Controller connected.");
			
			GCController *controller = notification.object;
			[_self logController:controller];
			[_self activateController:controller];
		}
	];
}

-(void)dealloc
{
	NSLog(@"Dealloc Controls.");
	[self deactivateController:_controller];
	
	[[NSNotificationCenter defaultCenter] removeObserver:_controllerConnectedObserver];
	_controllerConnectedObserver = nil;
}
#endif

-(void)update:(CCTime)delta
{
#if ANDROID
	CGPoint aim = _virtualAimJoystick.direction;
#else
	CGPoint aim = CGPointZero;
	
	if(_controller){
		aim = CGPointMake(_controllerAim.xAxis.value, _controllerAim.yAxis.value);
	} else {
		aim = _virtualAimJoystick.direction;
	}
#endif
	
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
#if ANDROID
	return _virtualJoystick.direction;
#else
	if(_controller){
		return cpvclamp(cpv(
			_controllerStick.xAxis.value,
			_controllerStick.yAxis.value
		), 1.0);
	} else {
		return _virtualJoystick.direction;
	}
#endif
}

-(CGPoint)aimDirection
{
#if ANDROID
	return _virtualAimJoystick.direction;
#else
	if(_controller){
		return cpvclamp(cpv(
			_controllerAim.xAxis.value,
			_controllerAim.yAxis.value
		), 1.0);
	} else {
		return _virtualAimJoystick.direction;
	}
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
	// Kind of a hack since CCButton doesn't support continuous events.
	[self setButtonValue:ControlRocketButton value:YES];
	[self setButtonValue:ControlRocketButton value:NO];
}

-(void)fireNova:(CCButton *)sender
{
	[self setButtonValue:ControlNovaButton value:YES];
	[self setButtonValue:ControlNovaButton value:NO];
}

-(BOOL)rocketButtonEnabled {return _rocketButton.enabled;}
-(void)setRocketButtonEnabled:(BOOL)rocketButtonEnabled {_rocketButton.enabled = rocketButtonEnabled;}
-(BOOL)rocketButtonVisible {return _rocketButton.parent.visible;}
-(void)setRocketButtonVisible:(BOOL)rocketButtonVisible {_rocketButton.parent.visible = rocketButtonVisible;}

-(BOOL)novaButtonEnabled {return _novaButton.enabled;}
-(void)setNovaButtonEnabled:(BOOL)novaButtonEnabled {_novaButton.enabled = novaButtonEnabled;}
-(BOOL)novaButtonVisible {return _novaButton.parent.visible;}
-(void)setNovaButtonVisible:(BOOL)novaButtonVisible {_novaButton.parent.visible = novaButtonVisible;}

@end
