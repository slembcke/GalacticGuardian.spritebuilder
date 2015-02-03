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

#import "GameController.h"


@implementation GameController

static GCController *SHARED_CONTROLLER = nil;

// Immutable array to avoid the need to copy during iteration.
static NSArray *CONTROLLER_DELEGATES = nil;

+(void)initialize
{
	if(self != [GameController class]) return;
	
	// Check that the OS has support for controllers. (iOS 7+, OS X 10.9+)
	if(NSClassFromString(@"GCController") == nil) return;
	
	CONTROLLER_DELEGATES = [NSArray array];
	
	// Note that I'm calling CCController and not GCController.
	// This is a subclass I made that adds support for USB/Bluetooth gamepads on Mac.
	for(GCController *controller in [CCController controllers]){
		[self activateSharedController:controller];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controllerConnected:) name:GCControllerDidConnectNotification object:nil];
}

+(void)controllerConnected:(NSNotification *)notification
{
	GCController *controller = notification.object;
	NSLog(@"GameController connected: %@", controller);
	[self activateSharedController:controller];
}

+(void)activateSharedController:(GCController *)controller
{
	if(SHARED_CONTROLLER == nil && controller.extendedGamepad){
		NSLog(@"GameController activated: %@", controller);
		SHARED_CONTROLLER = controller;
		
		for(id<GameControllerDelegate> delegate in CONTROLLER_DELEGATES){
			if([delegate respondsToSelector:@selector(controllerDidConnect)]) [delegate controllerDidConnect];
		}
		
		SHARED_CONTROLLER.controllerPausedHandler = ^(GCController *controller){
			for(id<GameControllerDelegate> delegate in CONTROLLER_DELEGATES){
				if([delegate respondsToSelector:@selector(pausePressed)]) [delegate pausePressed];
			}
		};
		
		SHARED_CONTROLLER.extendedGamepad.valueChangedHandler = ^(GCExtendedGamepad *gamepad, GCControllerElement *element){
			for(id<GameControllerDelegate> delegate in CONTROLLER_DELEGATES){
				if([delegate respondsToSelector:@selector(snapshotDidChange:)]) [delegate snapshotDidChange:gamepad.saveSnapshot.snapshotData];
			}
		};
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sharedControllerDisconnected:) name:GCControllerDidDisconnectNotification object:controller];
	}
}

+(void)sharedControllerDisconnected:(NSNotification *)notification
{
	GCController *controller = notification.object;
	NSLog(@"GameController disconnected: %@", controller);
	
	for(id<GameControllerDelegate> delegate in [CONTROLLER_DELEGATES copy]){
		if([delegate respondsToSelector:@selector(controllerDidDisconnect)]) [delegate controllerDidDisconnect];
	}
	
	SHARED_CONTROLLER = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:GCControllerDidDisconnectNotification object:controller];
}

+(void)addDelegate:(id<GameControllerDelegate>)delegate
{
	CONTROLLER_DELEGATES = [CONTROLLER_DELEGATES arrayByAddingObject:delegate];
	if([delegate respondsToSelector:@selector(controllerDidConnect)]) [delegate controllerDidConnect];
}

+(void)removeDelegate:(id<GameControllerDelegate>)delegate
{
	NSMutableArray *arr = [CONTROLLER_DELEGATES mutableCopy];
	[arr removeObject:delegate];
	
	CONTROLLER_DELEGATES = arr;
	if([delegate respondsToSelector:@selector(controllerDidDisconnect)]) [delegate controllerDidDisconnect];
}

@end
