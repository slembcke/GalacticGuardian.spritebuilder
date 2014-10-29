#import "SpaceBucks.h"

@implementation SpaceBucks

-(void)onEnter
{
	CCPhysicsBody *body = self.physicsBody;
	
	// This is used to pick which collision delegate method to call, see GameScene.m for more info.
	body.collisionType = @"pickup";
	
	// This sets up simple collision rules.
	// First you list the categories (strings) that the object belongs to.
	body.collisionCategories = @[@"pickup"];
	// Then you list which categories its allowed to collide with.
	body.collisionMask = @[@"ship"];
	
	[super onEnter];
}

@end
