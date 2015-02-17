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

// Left/right joystick values.
-(CGPoint)thrustDirection;
-(CGPoint)aimDirection;

// Check if a certain button is pressed.
-(BOOL)getButton:(ControlButton)button;

// Set a callback for when a button is pressed or released.
-(void)setHandler:(ControlHandler)block forButton:(ControlButton)button;

- (void) setNovaBombs:(int)bombs;

@end
