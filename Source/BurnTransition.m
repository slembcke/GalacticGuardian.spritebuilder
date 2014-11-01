#include "BurnTransition.h"


@interface CCTransition()
- (void)startTransition:(CCScene *)scene;
@end


@implementation BurnTransition

+(instancetype)burnTransitionWithDuration:(CCTime)duration;
{
	return (BurnTransition *)[self transitionCrossFadeWithDuration:duration];
}

- (void)startTransition:(CCScene *)scene
{
	[super startTransition:scene];
	
	
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
