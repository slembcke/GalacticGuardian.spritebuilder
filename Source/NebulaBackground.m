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
	
	// This is the purple-ish texture for the nebula.
	NebulaTexture = [CCTexture textureWithFile:@"Nebula.png"];
	NebulaTexture.contentScale = 2.0;
	
	// We want to make the texture repeate endlessly, but it's not exposed by the public API in 3.x...
	// This is not generally safe to do with cached textures.
	// Cocos2D 4.0 will fix the API problems however.
	NebulaTexture.texParameters = &(ccTexParams){GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
	
	// This is a grayscale texture that holds how far away the background is.
	// The Nebula.fsh shader uses this to apply some subtle, but cheap 3D effects.
	DepthMap = [CCTexture textureWithFile:@"NebulaDepth.png"];
	DepthMap.texParameters = &(ccTexParams){GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
	
	// This is the texture that is used by sprites/particles for drawing into the distortion map.
	DistortionTexture = [CCTexture textureWithFile:@"DistortionTexture.png"];
	[DistortionTexture generateMipmap];
}

// Toggled from the pause menu.
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
		
		// Set up the distortion map render texture.
		// This is a used to apply distortions to the screen.
		// The red channel controls how much distortion in the x direction.
		// The green channel controls the distortion in the y direction.
		CGSize size = [CCDirector sharedDirector].viewSize;
		_distortionMap = [CCRenderTexture renderTextureWithWidth:size.width height:size.height];
		
		// Create the distortion texture to be 1/4 the size of the screen (in pixels).
		// This saves a lot of fillrate on the GPU for slower devices like the iPad 2.
		_distortionMap.contentScale /= 4.0;
		_distortionMap.texture.antialiased = YES;
		
		// Clear the red/green channels to 0.5 so there is no distortion.
		[_distortionMap beginWithClear:0.5 g:0.5 b:0.0 a:0.0];
		[_distortionMap end];
		
		// Set up the Nebula shader.
		self.shader = ShaderMode;
		
		// The values are read by the shaders (Nebula.fsh/vsh)
		self.shaderUniforms[@"u_ParallaxAmount"] = @(0.09);
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

- (void)viewDidResizeTo:(CGSize)newViewSize
{
    [self setTextureRect:(CGRect){CGPointZero, newViewSize}];
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