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

#import "Constants.h"
#import "ShipSelectionScene.h"


@implementation ShipSelectionScene {
	CCSprite9Slice *_shieldBarSprite;
	CCSprite9Slice *_speedBarSprite;
	CCSprite9Slice *_powerBarSprite;

	CCNode *_shipNode;
	CCNode *_viewNode;
	
	int _shipIndex;
	
	CCLabelTTF *_shipNameLabel;
	
}

const float ship_shields[] = {60.0f, 70.0f, 20.0f};
const float ship_speeds[] = {100.0f, 40.0f, 70.0f};
const float ship_powers[] = {30.0f, 80.0f, 100.0f};


-(CCProgressNode *)setupBarFromSprite:(CCSprite *)sprite
{
	[sprite removeFromParent];
	CCProgressNode * bar = [CCProgressNode progressWithSprite:sprite];
	bar.type = CCProgressNodeTypeBar;
	bar.midpoint = CGPointZero;
	bar.barChangeRate = ccp(1.0f, 0.0f);
	bar.positionType = [sprite positionType];
	bar.scale = [sprite scale];
	bar.position = [sprite position];
	[_viewNode addChild:bar];
	return bar;
}

-(void)didLoadFromCCB
{
	self.contentSize = [CCDirector sharedDirector].designSize;
	self.contentSizeType = CCSizeTypePoints;
	
	// Make the "no physics node" warning go away.
	_shipNode.physicsBody = nil;
	
	[self showShip:_shipIndex];
}

-(void)dealloc
{
	CCLOG(@"ShipSelection dealloc");
}

-(void)dismiss:(id)sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	CCTransition *fade = [CCTransition transitionCrossFadeWithDuration:0.25];
	[[CCDirector sharedDirector] popSceneWithTransition:fade];
}

-(void) launch;
{
	CCTransition *fade = [CCTransition transitionCrossFadeWithDuration:0.25];
	[[CCDirector sharedDirector] popSceneWithTransition:fade];
	
	[_mainMenu launchWithShip:_shipIndex];
}

-(void) nextShip;
{
	_shipIndex = (_shipIndex + 1) % 3;
	[self showShip:_shipIndex];
}

-(void) prevShip;
{
	_shipIndex = (_shipIndex - 1 + 3) % 3;
	[self showShip:_shipIndex];
}

-(void) showShip:(ShipType) shipType
{
	[_shipNode removeFromParent];
	CCNode *oldShip = _shipNode;
	{
		float rotation = _shipNode.rotation;

		NSString * shipArt = ship_fileNames[shipType];
		_shipNode = [CCBReader load:[NSString stringWithFormat:@"%@-1", shipArt]];
		_shipNode.position = [oldShip position];
		_shipNode.rotation = rotation;
		_shipNode.scale = 1.5f;
		
		// The CCB file had physics set up in it, but we want to disable that on the menu.
		_shipNode.physicsBody = nil;
		
		[_viewNode addChild:_shipNode];
		
		// Rotate constantly
		[_shipNode runAction:[CCActionRepeatForever actionWithAction:[CCActionRotateBy actionWithDuration:1.0 angle:-180.0]]];
	}
	
	[_shipNameLabel setString: ship_names[shipType]];
}

// Animate the 9-slice sprite's width.
static void
LerpBarWidth(CCNode *bar, float newWidth, float lerpFactor)
{
	CGSize oldSize = bar.contentSize;
	bar.contentSize = CGSizeMake(oldSize.width + lerpFactor*(newWidth - oldSize.width), oldSize.height);
}

-(void)update:(CCTime)delta
{
	// Lerp to within 1% of the desired value when compared to one second ago.
	float factor = 1.0 - powf(0.01, delta);
	
	LerpBarWidth(_speedBarSprite, 2.0*ship_speeds[_shipIndex], factor);
	LerpBarWidth(_powerBarSprite, 2.0*ship_powers[_shipIndex], factor);
	LerpBarWidth(_shieldBarSprite, 2.0*ship_shields[_shipIndex], factor);
}

@end
