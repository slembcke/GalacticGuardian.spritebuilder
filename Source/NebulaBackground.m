// Used for setting the texture repeat.
// TODO find a workaround or fix the API? Ugh.
#import "CCTexture_Private.h"

#import "NebulaBackground.h"


@implementation NebulaBackground {
	CCRenderTexture *_distortionMap;
	
	id _modeObserver;
}

static CCShader *ShaderMode = nil;

static CCTexture *NebulaTexture = nil;
static CCTexture *DepthMap = nil;
static CCTexture *DistortionTexture = nil;

// These textures all need to be loaded with special settings.
// Might as well pre-load and permanently cache them.
+(void)initialize
{
	ShaderMode = [CCShader shaderNamed:@"Nebula"];
	
	NebulaTexture = [CCTexture textureWithFile:@"Nebula.png"];
	NebulaTexture.contentScale = 2.0;
	NebulaTexture.texParameters = &(ccTexParams){GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
	
	DepthMap = [CCTexture textureWithFile:@"NebulaDepth.png"];
	DepthMap.texParameters = &(ccTexParams){GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
	
	DistortionTexture = [CCTexture textureWithFile:@"DistortionTexture.png"];
	[DistortionTexture generateMipmap];
}

+(NSString *)toggleDistortionMode
{
	static int mode = 0;
	mode = (mode + 1)%3;
	
	CCShader *shaders[] = {
		[CCShader shaderNamed:@"Nebula"],
		[CCShader positionTextureColorShader],
		[CCShader shaderNamed:@"NebulaDebug"],
	};
	ShaderMode = shaders[mode];
	
	NSString *names[] = {
		@"On",
		@"Off",
		@"Debug",
	};
	return names[mode];
}

-(id)init
{
	if((self = [super initWithTexture:NebulaTexture])){
		self.anchorPoint = CGPointZero;
		
		// Disable alpha blending to save some fillrate.
		self.blendMode = [CCBlendMode disabledMode];
		
		// Set up the distortion map render texture;
		CGSize size = [CCDirector sharedDirector].viewSize;
		_distortionMap = [CCRenderTexture renderTextureWithWidth:size.width height:size.height];
		_distortionMap.contentScale /= 4.0;
		_distortionMap.texture.antialiased = YES;
		
		// Set the distortion map to no offset. 
		[_distortionMap beginWithClear:0.5 g:0.5 b:0.0 a:0.0];
		[_distortionMap end];
		
		// Apply the Nebula shader that applies some subtle parallax mapping and distortions.
		self.shader = ShaderMode;
		self.shaderUniforms[@"u_ParallaxAmount"] = @(0.06);
		self.shaderUniforms[@"u_DepthMap"] = DepthMap;
		self.shaderUniforms[@"u_DistortionMap"] = _distortionMap.texture;
		
		_distortionNode = [CCNode node];
	}
	
	return self;
}

-(void)setContentSize:(CGSize)contentSize
{
	[super setContentSize:contentSize];
	[_distortionNode setContentSize:contentSize];
}

-(void)onEnter
{
	// Set the shader again just in case the setting was changed in the pause menu.
	self.shader = ShaderMode;
	
	// Setup the texture rect once the node is added to the scene and we can calculate the content size.
	CGRect rect = {CGPointZero, self.contentSizeInPoints};
	self.textureRect = rect;
	
	// Forward onEnter to the distortion node.
	[_distortionNode onEnter];
	
	[super onEnter];
}

-(void)onExit
{
	// Forward onExit to the distortion node.
	[_distortionNode onExit];
	
	[super onExit];
}

-(void)draw:(CCRenderer *)renderer transform:(const GLKMatrix4 *)transform
{
	// Distortions might be disabled, skip the render texture pass.
	if(self.shader != [CCShader positionTextureColorShader]){
		// Update the distortion map with whatever is in the distortion node.
		CCRenderer *rtRenderer = [_distortionMap beginWithClear:0.5 g:0.5 b:0.0 a:0.0];
			// Use the background's transform so that the distortion node is drawn relative to it.
			[_distortionNode visit:rtRenderer parentTransform:transform];
		[_distortionMap end];
	}
	
	[super draw:renderer transform:transform];
}

@end