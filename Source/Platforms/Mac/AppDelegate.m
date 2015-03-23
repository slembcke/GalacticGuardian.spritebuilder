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
#import "CCWwise.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet CCGLView *glView;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Use iPhone 5 size a base size/ratio.
	CGSize defaultSize = CGSizeMake(568.0, 320.0);
	
	// Set 0.0 for fullscreen mode.
	CGFloat inset = 100.0;
	
	NSWindow *window = self.window;
	[window setFrame:CGRectInset([NSScreen mainScreen].visibleFrame, inset, inset) display:NO];
	
	// Fullscreen?
	if(inset == 0.0){
		window.styleMask = NSBorderlessWindowMask;
		window.backingType = NSBackingStoreBuffered;
		window.level = NSMainMenuWindowLevel + 1;
		
		[window setFrame:[NSScreen mainScreen].frame display:NO];
	}
	
	CGFloat scaleW = (window.frame.size.width)/defaultSize.width;
	CGFloat scaleH = (window.frame.size.height)/defaultSize.height;
	CGFloat scale = MAX(1.0, MIN(scaleW, scaleH));

	CCDirectorMac *director = (CCDirectorMac*)[CCDirector sharedDirector];

	// connect the OpenGL view with the director
	[director setView:self.glView];
	director.resizeMode = kCCDirectorResize_NoScale;
	director.contentScaleFactor = scale*[NSScreen mainScreen].backingScaleFactor;

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
	
    
    CCWwise *w = [CCWwise sharedManager];
    [w loadBank:@"Init.bnk"];
    [w loadBank:@"GGSoundbank.bnk"];
    
    
	[MainMenu class];
	[director runWithScene:[[GameScene alloc] initWithShipType:Ship_Herald]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

@end
