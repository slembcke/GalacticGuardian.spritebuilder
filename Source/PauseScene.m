#import "Constants.h"
#import "NebulaBackground.h"
#import "PauseScene.h"

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

-(void)dealloc
{
	NSLog(@"PauseScene dealloc");
}

-(void)musicVolumeChanged:(CCSlider *)slider
{
	[[NSUserDefaults standardUserDefaults] setFloat:slider.sliderValue forKey:DefaultsMusicKey];
	
	[OALSimpleAudio sharedInstance].bgVolume = slider.sliderValue;
}

-(void)soundVolumeChanged:(CCSlider *)slider
{
	[[NSUserDefaults standardUserDefaults] setFloat:slider.sliderValue forKey:DefaultsSoundKey];
	
	[OALSimpleAudio sharedInstance].effectsVolume = slider.sliderValue;
	[[OALSimpleAudio sharedInstance] playEffect:@"TempSounds/Laser.wav" volume:0.25 pitch:1.0 pan:0.0 loop:NO];
}

-(void)toggleDistortionMode:(CCButton *)button
{
	NSString *mode = [NebulaBackground toggleDistortionMode];
	button.title = [NSString stringWithFormat:@"Distortion: %@", mode];
}

-(void)dismiss:(id)sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	CCTransition *fade = [CCTransition transitionCrossFadeWithDuration:0.25];
	[[CCDirector sharedDirector] popSceneWithTransition:fade];
}

-(void)endGame:(id)sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[[CCDirector sharedDirector] popScene];
	[[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"MainMenu"]];
}

@end
