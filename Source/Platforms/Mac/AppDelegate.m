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

#import <Cocoa/Cocoa.h>

#import "MainMenu.h"
#import "GameScene.h"


@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet CCGLView *glView;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	CGSize defaultSize = CGSizeMake(640.0, 360.0);
	CGRect screenFrame = [NSScreen mainScreen].visibleFrame;
	CGFloat inset = 100.0;
	
	CGFloat scaleW = (screenFrame.size.width - 2.0*inset)/defaultSize.width;
	CGFloat scaleH = (screenFrame.size.height - 2.0*inset)/defaultSize.height;
	CGFloat windowScale = MAX(1.0, MIN(scaleW, scaleH));
	
	CGSize windowSize = CC_SIZE_SCALE(defaultSize, windowScale);
	CGRect windowFrame = CGRectMake(
		(screenFrame.size.width - windowSize.width)/2.0,
		(screenFrame.size.height - windowSize.height)/2.0,
		windowSize.width,
		windowSize.height
	);
	
	[self.window setFrame:windowFrame display:NO animate:NO];

	CCDirectorMac *director = (CCDirectorMac*)[CCDirector sharedDirector];

	// connect the OpenGL view with the director
	[director setView:self.glView];
	director.resizeMode = kCCDirectorResize_NoScale;
	director.contentScaleFactor = windowScale*[NSScreen mainScreen].backingScaleFactor;

	[[CCFileUtils sharedFileUtils] setMacContentScaleFactor:2.0];
	[CCFileUtils sharedFileUtils].directoriesDict = [@{
		@"mac": @"resources-phonehd",
		@"machd": @"resources-tablethd",
		@"": @"",
	} mutableCopy];

	[CCFileUtils sharedFileUtils].searchPath = @[
		[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Published-iOS"],
		[[NSBundle mainBundle] resourcePath],
	];
	
	[CCFileUtils sharedFileUtils].searchResolutionsOrder = [@[
		@"machd",
		@"mac",
		@"default",
	] mutableCopy];

	[CCFileUtils sharedFileUtils].searchMode = CCFileUtilsSearchModeDirectory;

	[[CCFileUtils sharedFileUtils] loadFilenameLookupDictionaryFromFile:@"fileLookup.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] loadSpriteFrameLookupDictionaryFromFile:@"spriteFrameFileList.plist"];
	
	[MainMenu class];
	[director runWithScene:[[GameScene alloc] initWithShipType:Ship_Herald]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

@end
