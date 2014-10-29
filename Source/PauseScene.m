#import "Constants.h"
#import "NebulaBackground.h"


@interface PauseScene : CCScene @end
@implementation PauseScene {
	CCSlider *_musicSlider;
	CCSlider *_soundSlider;
}

-(void)didLoadFromCCB
{
	self.contentSize = [CCDirector sharedDirector].designSize;
	self.contentSizeType = CCSizeTypePoints;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	_musicSlider.sliderValue = [[defaults objectForKey:DefaultsMusicKey] floatValue];
	_soundSlider.sliderValue = [[defaults objectForKey:DefaultsSoundKey] floatValue];
}

-(void)musicVolumeChanged:(CCSlider *)slider
{
	[[NSUserDefaults standardUserDefaults] setFloat:slider.sliderValue forKey:DefaultsMusicKey];
	
	// TODO set music volume.
}

-(void)soundVolumeChanged:(CCSlider *)slider
{
	[[NSUserDefaults standardUserDefaults] setFloat:slider.sliderValue forKey:DefaultsSoundKey];
	
	// TODO set sound volume
}

-(void)toggleDistortionMode:(CCButton *)button
{
	NSString *mode = [NebulaBackground toggleDistortionMode];
	button.title = [NSString stringWithFormat:@"Distortions: %@", mode];
}

-(void)dismiss:(id)sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	CCTransition *fade = [CCTransition transitionCrossFadeWithDuration:0.25];
	[[CCDirector sharedDirector] popSceneWithTransition:fade];
}

@end
