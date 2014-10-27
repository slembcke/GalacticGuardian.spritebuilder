#import "CCTexture_Private.h"

@interface NebulaBackground : CCSprite @end
@implementation NebulaBackground

-(id)init
{
	// Explicitly load and configure the nebula texture.
	CCTexture *texture = [CCTexture textureWithFile:@"Nebula.png"];
	texture.contentScale = 2.0;
	texture.texParameters = &(ccTexParams){GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
	
	CCTexture *depth = [CCTexture textureWithFile:@"NebulaDepth.png"];
	depth.texParameters = &(ccTexParams){GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
	
	if((self = [super initWithTexture:texture])){
		// Disable alpha blending to save some fillrate.
		self.blendMode = [CCBlendMode disabledMode];
		
		// Apply the Nebula shader that applies some subtle parallax mapping and distortions.
		self.shader = [CCShader shaderNamed:@"Nebula"];
		
		// Configure the shader
		self.shaderUniforms[@"u_ParallaxAmount"] = @0.08;
		self.shaderUniforms[@"u_DepthTexture"] = depth;
	}
	
	return self;
}

-(void)onEnter
{
	// Setup the texture rect once the node is added to the scene and we can calculate the content size.
	CGRect rect = {CGPointZero, self.contentSizeInPoints};
	self.textureRect = rect;
	
	[super onEnter];
}

@end