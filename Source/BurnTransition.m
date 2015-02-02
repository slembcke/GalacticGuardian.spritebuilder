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

#include "BurnTransition.h"


@interface CCTransition()
- (void)startTransition:(CCScene *)scene;
@end


@implementation BurnTransition

+(instancetype)burnTransitionWithDuration:(CCTime)duration;
{
	return (BurnTransition *)[self transitionCrossFadeWithDuration:duration];
}

// Transitions are not meant to be subclassable in v3.x, but this was too good to pass up.
// This code is *not* going to be very future proof, but it works okay with 3.3 and 3.4.
- (void)startTransition:(CCScene *)scene
{
	[super startTransition:scene];
	
	// Force the BurnSprite class to be loaded since we use the shader and global shader uniforms set there.
	[NSClassFromString(@"BurnSprite") class];
	
	CCShader *shader = [CCShader shaderNamed:@"BurnSprite"];
	NSDictionary *uniforms = @{
		@"u_BurnScale": @(1.0),
		@"u_MinChar": @(1.0),
		@"u_MaxChar": @(0.0),
		@"u_CharSmooth": @(0.07),
		@"u_CharWidth": @(0.1),
		@"u_GlowSmooth": @(0.03),
	};
	
	CCColor *burnColor = [CCColor colorWithCcColor3b:ccc3(255, 134, 36)];
	
	// Use Obj-C reflection to access the private variables of the transition class so we can set up the shader.
	
	CCRenderTexture *incoming = object_getIvar(self, class_getInstanceVariable(self.class, "_incomingTexture"));
	incoming.sprite.shader = shader;
	[incoming.sprite.shaderUniforms addEntriesFromDictionary:uniforms];
	incoming.sprite.color = burnColor;
	
	CCRenderTexture *outgoing = object_getIvar(self, class_getInstanceVariable(self.class, "_outgoingTexture"));
	outgoing.sprite.shader = shader;
	[outgoing.sprite.shaderUniforms addEntriesFromDictionary:uniforms];
	outgoing.sprite.color = burnColor;
}

@end
