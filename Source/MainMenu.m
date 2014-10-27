#import "MainMenu.h"
#import "NebulaBackground.h"

@implementation MainMenu {
	NebulaBackground *_background;
	CCTime _time;
}

-(id)init
{
	if((self = [super init])){
		
	}
	
	return self;
}

-(void)update:(CCTime)delta
{
	_time += delta;
	
	// There is a simple hack in the vertex shader to make the nebula scroll.
	_background.shaderUniforms[@"u_ScrollOffset"] = [NSValue valueWithCGPoint:ccp(0.0, fmod(_time/4.0, 1.0))];
}

@end
