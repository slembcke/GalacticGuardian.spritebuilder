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
#import "CCSprite_Private.h"


@interface BurnSprite : CCSprite @end
@implementation BurnSprite

static CCShader *BurnShader = nil;

+(void)initialize
{
	if(self != [BurnSprite class]) return;
	
	CCTexture *burnTexture = [CCTexture textureWithFile:@"BurnTexture.png"];
	burnTexture.texParameters = &(ccTexParams){GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
	[burnTexture generateMipmap];
	
	// Normally when you use shaders, you set the shader uniforms for each node.
	// This is easy to use, but custom shader uniforms disable batching.
	// Since we will be drawing many pieces of burning debris at a time, we want to batch them!
	
	// Instead, you can use the global shader uniforms to pass the same shader values for every object drawn.
	// That's okay because we only need to pass the burn color for each sprite, and we can pass that using the sprite's regular color property.
	NSMutableDictionary *globals = [CCDirector sharedDirector].globalShaderUniforms;
	globals[@"u_BurnScale"] = @(6.0);
	globals[@"u_BurnTexture"] = burnTexture;
	globals[@"u_MinChar"] = @(0.20);
	globals[@"u_MaxChar"] = @(0.05);
	globals[@"u_CharSmooth"] = @(0.05);
	globals[@"u_CharWidth"] = @(0.50);
	globals[@"u_GlowSmooth"] = @(0.15);
	
	BurnShader = [CCShader shaderNamed:@"BurnSprite"];
}

-(id)initWithTexture:(CCTexture *)texture rect:(CGRect)rect rotated:(BOOL)rotated
{
	if((self = [super initWithTexture:texture rect:rect rotated:rotated])){
		self.shader = BurnShader;
	}
	
	return self;
}

@end
