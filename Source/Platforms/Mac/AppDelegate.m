#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet CCGLView *glView;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    CCDirectorMac *director = (CCDirectorMac*) [CCDirector sharedDirector];

    // enable FPS and SPF
    // [director setDisplayStats:YES];

    // connect the OpenGL view with the director
    [director setView:self.glView];
		director.resizeMode = kCCDirectorResize_NoScale;
		director.contentScaleFactor *= 2.0;

    // 'Effects' don't work correctly when autoscale is turned on.
    // Use kCCDirectorResize_NoScale if you don't want auto-scaling.
    //[director setResizeMode:kCCDirectorResize_NoScale];

    // Enable "moving" mouse event. Default no.
    [self.window setAcceptsMouseMovedEvents:NO];

    // Center main window
    [self.window center];
	
	
    // Configure CCFileUtils to work with SpriteBuilder
//    [CCBReader configureCCFileUtils];
	
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
