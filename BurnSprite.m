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
	
	[CCDirector sharedDirector].globalShaderUniforms[@"u_BurnTexture"] = burnTexture;
	
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
