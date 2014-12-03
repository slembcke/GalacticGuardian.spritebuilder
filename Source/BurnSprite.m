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
	
	// Set up global uniforms so we can batch the sprites.
	NSMutableDictionary *globals = [CCDirector sharedDirector].globalShaderUniforms;
	globals[@"u_BurnScale"] = @(3.0);
	globals[@"u_BurnTexture"] = burnTexture;
	globals[@"u_MinChar"] = @(0.70);
	globals[@"u_MaxChar"] = @(0.40);
	globals[@"u_CharSmooth"] = @(0.05);
	globals[@"u_CharWidth"] = @(0.35);
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
