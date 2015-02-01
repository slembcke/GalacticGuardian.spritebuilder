#import "AppDelegate.h"

@interface AppDelegate ()

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

	[CCFileUtils sharedFileUtils].searchMode = CCFileUtilsSearchModeDirectory;
	[[CCFileUtils sharedFileUtils] buildSearchResolutionsOrder];

	[[CCFileUtils sharedFileUtils] loadFilenameLookupDictionaryFromFile:@"fileLookup.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] loadSpriteFrameLookupDictionaryFromFile:@"spriteFrameFileList.plist"];

	[director runWithScene:[CCBReader loadAsScene:@"MainMenu"]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

@end
