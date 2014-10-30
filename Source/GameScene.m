	//
//  GameScene.m
//  Galactic Guardian
//
//  Created by Scott Lembcke
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCPhysics+ObjectiveChipmunk.h"

#import "Constants.h"

#import "GameScene.h"

#import "Controls.h"
#import "NebulaBackground.h"
#import "PlayerShip.h"
#import "EnemyShip.h"
#import "Bullet.h"
#import "Rocket.h"
#import "SpaceBucks.h"


@implementation GameScene
{
	CCNode *_scrollNode;
	float _clampWidth, _clampHeight;
	
	CCPhysicsNode *_physics;
	NebulaBackground *_background;
	
	Controls *_controls;
	PlayerShip *_playerShip;
	
	CCTime _fixedTime;
	
	CCProgressNode *levelProgress;
	
	NSMutableArray *_pickups;
	
	int _enemies_killed;
	int _ship_level;
	int _spaceBucks;
	int _spaceBucksTilNextLevel;
}

-(instancetype)initWithShipType:(NSString *)shipType level:(int) shipLevel
{
	if((self = [super init])){
		_ship_level = shipLevel;
		
		_spaceBucks = 0;
		_spaceBucksTilNextLevel = 40;
		
		CGSize viewSize = [CCDirector sharedDirector].viewSize;
		
		[self setupControls];
		
		_scrollNode = [CCNode node];
		_scrollNode.contentSize = CGSizeMake(1.0, 1.0);
		_scrollNode.position = ccp(viewSize.width/2.0, viewSize.height/2.0);
		[self addChild:_scrollNode z:Z_SCROLL_NODE];
		
		_clampWidth = (GameSceneSize.width - viewSize.width)/2.0;
		_clampHeight = (GameSceneSize.height - viewSize.height)/2.0;
		
		_background = [NebulaBackground node];
		_background.contentSize = GameSceneSize;
		[_scrollNode addChild:_background z:Z_NEBULA];
		
		_physics = [CCPhysicsNode node];
		[_scrollNode addChild:_physics z:Z_PHYSICS];
		
		_physics.iterations = 1;
		
		// Use the gamescene as the collision delegate.
		// See the ccPhysicsCollision* methods below.
		_physics.collisionDelegate = self;
		
		// Enable to show debug outlines for Physics shapes.
//		_physics.debugDraw = YES;
		
		CCNode *bounds = [CCNode node];
		CGFloat boundsWidth = 50.0;
		CGRect boundsRect = CGRectMake(-boundsWidth, -boundsWidth, GameSceneSize.width + 2.0*boundsWidth, GameSceneSize.height + 2.0*boundsWidth);
		bounds.physicsBody = [CCPhysicsBody bodyWithPolylineFromRect:boundsRect cornerRadius:boundsWidth];
		bounds.physicsBody.collisionCategories = @[CollisionCategoryBarrier];
		bounds.physicsBody.collisionMask = @[CollisionCategoryPlayer];
		bounds.physicsBody.elasticity = 1.0;
		[_physics addChild:bounds];
		
		_enemies = [NSMutableArray array];
		_pickups = [NSMutableArray array];
		
		// Add a ship in the middle of the screen.
		_ship_level = shipLevel;
		[self createPlayerShipAt: ccp(GameSceneSize.width/2.0, GameSceneSize.height/2.0) ofType:shipType];
		
		[self scheduleBlock:^(CCTimer *timer) {
			EnemyShip *enemy = (EnemyShip *)[CCBReader load:@"BadGuy1"];
			if(CCRANDOM_0_1() > 0.33f){
				// left or right sides.
				enemy.position = ccp(CCRANDOM_0_1() > 0.5f ? -64.0f : GameSceneSize.width + 64.0f, CCRANDOM_MINUS1_1() * 400.0f + GameSceneSize.height / 2.0f);
			}else{
				// Top:
				enemy.position = ccp(CCRANDOM_MINUS1_1() * 400.0f + GameSceneSize.width / 2.0f, GameSceneSize.height + 64.0f);
			}

			[_physics addChild:enemy z:Z_ENEMY];
			[_enemies addObject:enemy];
			
			[timer repeatOnceWithInterval:1.5f];
		} delay:1.0f];
		
		for(int i = 0; i < 20; i++){
			// maybe this spoke/circle pattern will be cool.
			float angle = (M_PI * 2.0f / 20.0f) * i;
			[self addWallAt: ccpAdd(ccpMult(ccpForAngle(angle), 150.0f + 250.0f * CCRANDOM_0_1() ), ccp(512, 512))];
		}
		
		
		
		// setup interface:
		CCSprite *levelProgressBG = [CCSprite spriteWithImageNamed:@"UI/bgBar.png"];
		levelProgressBG.anchorPoint = ccp(0, 1);
		levelProgressBG.positionType = CCPositionTypeMake(CCPositionUnitUIPoints, CCPositionUnitUIPoints, CCPositionReferenceCornerTopLeft);
		levelProgressBG.position = ccp(20, 20);
		[self addChild:levelProgressBG];
		
		levelProgress = [CCProgressNode progressWithSprite:[CCSprite spriteWithImageNamed:@"UI/yellowBar.png"]];
		levelProgress.type = CCProgressNodeTypeBar;
		levelProgress.midpoint = CGPointZero;
		levelProgress.barChangeRate = ccp(1.0f, 0.0f);
		levelProgress.anchorPoint = ccp(0, 1);
		levelProgress.positionType = CCPositionTypeMake(CCPositionUnitUIPoints, CCPositionUnitUIPoints, CCPositionReferenceCornerTopLeft);
		levelProgress.position = ccp(20, 20);
		[self addChild:levelProgress];
		
		levelProgress.percentage = (float) _spaceBucks;
		
		// Enable touch events.
		// The entire scene is used as a shoot button.
		self.userInteractionEnabled = YES;
		
	}
	
	return self;
}

-(void)setupControls
{
	_controls = [Controls node];
	[self addChild:_controls z:Z_CONTROLS];
	
	__weak typeof(self) _self = self;
	[_controls setHandler:^(BOOL state) {if(state) [_self pause];} forButton:ControlPauseButton];
	[_controls setHandler:^(BOOL state) {if(state) [_self fireRocket];} forButton:ControlRocketButton];
}

-(void)addWallAt:(CGPoint) pos
{
	CCNode *wall = (CCNode *)[CCBReader load:@"Asteroid"];
	wall.position = pos;
	wall.rotation = CCRANDOM_0_1() * 360.0f;
	[_physics addChild:wall z:Z_ENEMY];
}

-(void)fixedUpdate:(CCTime)delta
{
	_fixedTime += delta;
	
	// Fly the ship using the joystick controls.
	[_playerShip ggFixedUpdate:delta withControls:_controls];
	_playerPosition = _playerShip.position;
	
	if([_controls getButton:ControlFireButton]){
		if(_playerShip.lastFireTime + (1.0f / _playerShip.fireRate) < _fixedTime){
			[self fireBullet];
		}
	}
	
	for (EnemyShip *e in _enemies) {
		[e ggFixedUpdate:delta scene:self];
	}
	for (SpaceBucks *sb in _pickups) {
		[sb ggFixedUpdate:delta scene:self];
	}
	
	
}

-(void)setScrollPosition:(CGPoint)scrollPosition
{
	float smoothing = 1e3;
	
	CGPoint exp = CGPointMake(
		(scrollPosition.x - GameSceneSize.width/2.0)/_clampWidth,
		(scrollPosition.y - GameSceneSize.height/2.0)/_clampHeight
	);
	
	CGPoint offset = CGPointMake(
		 _clampWidth*(log(pow(smoothing, -exp.x - 1.0) + 1.01) - log(pow(smoothing, exp.x - 1.0) + 1.01)),
		_clampHeight*(log(pow(smoothing, -exp.y - 1.0) + 1.01) - log(pow(smoothing, exp.y - 1.0) + 1.01))
	);
	
	_scrollNode.anchorPoint = ccpAdd(scrollPosition, ccpMult(offset, 1.0/log(smoothing)));
}

-(void)update:(CCTime)delta
{
	self.scrollPosition = _playerShip.position;
}


-(void)enemyDeath:(EnemyShip *)enemy from:(Bullet *) bullet;
{
	[enemy removeFromParent];
	[_enemies removeObject:enemy];
	
	if(![_playerShip isDead]){
		_enemies_killed += 1;
		
		// spawn loot:
		for(int i = 0; i < 10; i++){
			SpaceBuckType type = SpaceBuck_1;
			float n = CCRANDOM_0_1();
			if(n > 0.90f){
				type = SpaceBuck_8;
			}else if ( n > 0.70f){
				type = SpaceBuck_4;
			}
			
			SpaceBucks *pickup = [[SpaceBucks alloc] initWithAmount: type];
			pickup.position = enemy.position;
			[_pickups addObject:pickup];
			[_physics addChild:pickup z:Z_PICKUPS];
		}
	}
	
	CGPoint pos = enemy.position;
	
	CCNode *debris = [CCBReader load:enemy.debris];
	debris.position = pos;
	debris.rotation = enemy.rotation;
	
	CCColor *weaponColor = [CCColor colorWithRed:1.0f green:1.0f blue:0.3f];
	if(bullet != nil){
		weaponColor = bullet.bulletColor;
	}
	
	InitDebris(debris, debris, enemy.physicsBody.velocity, weaponColor);
	[_physics addChild:debris z:Z_DEBRIS];
	
	CCNode *explosion = [CCBReader load:@"Particles/ShipExplosion"];
	explosion.position = pos;
	[_physics addChild:explosion z:Z_PARTICLES];
	
	CCNode *distortion = [CCBReader load:@"DistortionParticles/SmallRing"];
	distortion.position = pos;
	[_background.distortionNode addChild:distortion];
	
	[self scheduleBlock:^(CCTimer *timer) {
		[debris removeFromParent];
		[explosion removeFromParent];
		[distortion removeFromParent];
	} delay:5];
	
	[[OALSimpleAudio sharedInstance] playEffect:@"TempSounds/Explosion.wav" volume:2.0 pitch:1.0 pan:0.0 loop:NO];
}

-(void)splashDamageAt:(CGPoint)center radius:(float)radius damage:(int)damage;
{
	for(EnemyShip *enemy in [_enemies copy]){
		float dist = ccpDistance(center, enemy.position);
		float splash = 1.0 - dist/radius;
		
		if(splash > 0.0 && [enemy takeDamage:round(splash*damage)]){
			[self enemyDeath:enemy from:nil];
		}
	}
}

-(void)drawBulletFlash:(Bullet *)fromBullet;
{
	[self drawFlash:fromBullet.position withImage:fromBullet.flashImagePath];
}

-(void)drawFlash:(CGPoint) position withImage:(NSString*) imagePath;
{
	float duration = 0.15;
	
	CCSprite *flash = [CCSprite spriteWithImageNamed:imagePath];
	flash.position = position;
	[_physics addChild:flash z:Z_FLASH];
	
	[flash runAction:[CCActionSequence actions:
		[CCActionSpawn actions:
			[CCActionFadeOut actionWithDuration:duration],
			[CCActionScaleTo actionWithDuration:duration scale:0.25],
			nil
		],
		[CCActionRemove action],
		nil
	]];
	
	// Draw a little distortion too
	CCSprite *distortion = [CCSprite spriteWithImageNamed:@"DistortionTexture.png"];
	distortion.position = position;
	distortion.scale = 0.15;
	distortion.opacity = 0.5;
	distortion.rotation = 360.0*CCRANDOM_0_1();
	[_background.distortionNode addChild:distortion];
	
	[distortion runAction:[CCActionSequence actions:
		[CCActionSpawn actions:
			[CCActionFadeOut actionWithDuration:duration],
			[CCActionScaleTo actionWithDuration:duration scale:0.5],
			nil
		],
		[CCActionRemove action],
		nil
	]];
}

-(void)fireBullet
{
	// Don't fire bullets if the ship is destroyed.
	if([_playerShip isDead]) return;
	_playerShip.lastFireTime = _fixedTime;
	
	// This is sort of a fancy math way to figure out where to fire the bullet from.
	// You could figure this out with more code, but I wanted to have fun with some maths.
	// This gets the transform of one of the "gunports" that I marked in the CCB file with a special node.
	CGAffineTransform transform = _playerShip.gunPortTransform;
	
	// An affine transform looks like this when written as a matrix:
	// | a, c, tx |
	// | b, d, ty |
	// The first column, (a, b), is the direction the new x-axis will point in.
	// The second column, (c, d), is the direction the new y-axis will point in.
	// The last column, (tx, ty), is the location of the origin of the new transform.
	
	// The position of the gunport is just the matrix's origin point (tx, ty).
	CGPoint position = ccp(transform.tx, transform.ty);

	// The transform's x-axis, (c, d), will point in the direction of the gunport.
	CGPoint direction = ccp(transform.a, transform.b);
	
	// So by "fancy math" I really just meant knowing what the numbers in a CGAffineTransform are. ;)
	
	// Now we can create the bullet with the position and direction.
	Bullet *bullet = [[Bullet alloc] initWithBulletLevel:_playerShip.bulletLevel];
	bullet.position = position;
	bullet.rotation = -CC_RADIANS_TO_DEGREES(ccpToAngle(direction)) + 90.0f;
	
	// Make the bullet move in the direction it's pointed.
	bullet.physicsBody.velocity = ccpMult(direction, bullet.speed);
	
	[_physics addChild:bullet z:Z_BULLET];
	
	// Draw a muzzle flash too!
	[self drawBulletFlash:bullet];
	
	// Make some noise. Add a little chromatically tuned pitch bending to make it more musical.
	int half_steps = (arc4random()%(2*4 + 1) - 4);
	float pitch = pow(2.0f, half_steps/12.0f);
	[[OALSimpleAudio sharedInstance] playEffect:@"TempSounds/Laser.wav" volume:0.25 pitch:pitch pan:0.0 loop:NO];
}

-(void)fireRocket
{
	// Don't fire bullets if the ship is destroyed.
	if([_playerShip isDead]) return;
	
	// TODO missile recharge logic
	
	CGAffineTransform transform = _playerShip.physicsBody.absoluteTransform;
	CGPoint position = ccp(transform.tx, transform.ty);
	CGPoint direction = ccp(transform.a, transform.b);
	
	Rocket *rocket = [Rocket rocketWithLevel:RocketSmall];
	rocket.position = position;
	rocket.rotation = -CC_RADIANS_TO_DEGREES(ccpToAngle(direction));
	
	// Make the rocket start at the ship's velocity.
	// Let it accelerate itself.
	rocket.physicsBody.velocity = _playerShip.physicsBody.velocity;
	
	[_physics addChild:rocket z:Z_BULLET];
}

void
InitDebris(CCNode *root, CCNode *node, CGPoint velocity, CCColor *burnColor)
{
	// If the node has a body, set some properties.
	CCPhysicsBody *body = node.physicsBody;
	body.collisionCategories = @[CollisionCategoryDebris];
	
	if(body){
		// Bodies with the same group reference don't collide.
		// Any type of object will do. It's the object reference that is important.
		// In this case, I want the debris to collide with everything except other debris from the same ship.
		// I'll use a reference to the root node since that is unique for each explosion.
		body.collisionGroup = root;
		
		// Copy the velocity onto the body + a little random.
		body.velocity = ccpAdd(velocity, ccpMult(CCRANDOM_IN_UNIT_CIRCLE(), 75.0));
		body.angularVelocity = 5.0*CCRANDOM_MINUS1_1();
		
		// Nodes with bodies should also be sprites.
		// This is a convenient place to add the fade action.
		node.color = burnColor;
		[node runAction: [CCActionSequence actions:
		 [CCActionDelay actionWithDuration:0.5],
		 [CCActionFadeOut actionWithDuration:2.0],
		 [CCActionRemove action],
		 nil
		]];
	}
	
	// Recurse on the children.
	for(CCNode *child in node.children) InitDebris(root, child, velocity, burnColor);
}

-(void)pause
{
	CCDirector *director = [CCDirector sharedDirector];
	CGSize viewSize = director.viewSize;
	
	CCScene *pause = (CCScene *)[CCBReader load:@"PauseScene"];
	
	CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:viewSize.width height:viewSize.height];
	rt.contentScale /= 4.0;
	rt.texture.antialiased = YES;
	
	GLKMatrix4 projection = director.projectionMatrix;
	CCRenderer *renderer = [rt begin];
		[self visit:renderer parentTransform:&projection];
	[rt end];
	
	CCSprite *screenGrab = [CCSprite spriteWithTexture:rt.texture];
	screenGrab.anchorPoint = ccp(0.0, 0.0);
	screenGrab.effect = [CCEffectStack effects:
		[CCEffectBlur effectWithBlurRadius:4.0],
		[CCEffectSaturation effectWithSaturation:-0.5],
		nil
	];
	[pause addChild:screenGrab z:-1];
	
	[director pushScene:pause withTransition:[CCTransition transitionCrossFadeWithDuration:0.25]];
}

-(void) createPlayerShipAt:(CGPoint) pos ofType:(NSString *) shipType
{
	_spaceBucks = 0;
	_spaceBucksTilNextLevel = _ship_level * 60 + 30;
	if(_ship_level >= 7){
		// Temp code:
		_spaceBucksTilNextLevel = 10000;
	}
	
	float rotation = 0.0f;
	if(_playerShip){
		rotation = _playerShip.rotation;
		
		[_playerShip removeFromParent];
	}
	
	int shipChassis = (_ship_level) / 2 + 1;
	_playerShip = (PlayerShip *)[CCBReader load:[NSString stringWithFormat:@"%@-%d", shipType, shipChassis ]];
	_playerShip.position = pos;
	_playerShip.name = shipType;
	[_physics addChild:_playerShip z:Z_PLAYER];
	[_background.distortionNode addChild:_playerShip.shieldDistortionSprite];
	_playerShip.bulletLevel = MIN(_ship_level, BulletRed2);
	
	// Center on the player.
	self.scrollPosition = _playerShip.position;
}

-(void) levelUp;
{
	
	_ship_level += 1;
	_playerShip.bulletLevel = MIN(_ship_level, BulletRed2);
	
	
	CGSize viewSize = [CCDirector sharedDirector].viewSize;

	[[OALSimpleAudio sharedInstance] playEffect:@"TempSounds/LevelUp.wav" volume:0.8 pitch:1.0 pan:0.0 loop:NO];
	
	CCLabelTTF *levelUpText = [CCLabelTTF labelWithString:@"More Awesome!" fontName:@"Helvetica" fontSize:36.0];
	[self addChild:levelUpText];
	levelUpText.position = ccp(viewSize.width / 2.0f, viewSize.height / 1.5f);
	levelUpText.anchorPoint = ccp(0.5, 0.5);

	
	[levelUpText setScale:2.0f];
	[levelUpText runAction:[CCActionSequence actions:
			[CCActionSpawn actions:
				[CCActionFadeIn actionWithDuration:0.15],
				[CCActionScaleTo actionWithDuration:0.25 scale:1.0],
				nil
			],
			[CCActionDelay actionWithDuration:0.95],
			[CCActionFadeOut actionWithDuration:0.35],
			[CCActionRemove action],
			nil
	]];
	
	[self createPlayerShipAt:_playerShip.position ofType:_playerShip.name];
	
	
}

-(CCNode *)distortionNode
{
	return _background.distortionNode;
}


#pragma mark - CCPhysicsCollisionDelegate methods


-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair ship:(PlayerShip *)player enemy:(EnemyShip *)enemy
{
	if([_playerShip takeDamage]){
		[_playerShip destroy];
		
		[self scheduleBlock:^(CCTimer *timer){
			// Go back to the menu after a short delay.
			[[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"MainMenu"]];
		} delay:5.0];
		
		// Don't process the collision so the enemy spaceship will survive and mock you.
		return NO;
	}else{
		// Player took damage, the enemy should self destruct.
		[self enemyDeath: enemy from:nil];
		return YES;
	}
	
	
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair bullet:(Bullet *)bullet enemy:(EnemyShip *)enemy
{
	[bullet destroy];
	
	if([enemy takeDamage:1]){
		[self enemyDeath:enemy from:bullet];
	}
	
	return NO;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair bullet:(Bullet *)bullet wall:(CCNode *)wall
{
	[bullet destroy];
	return NO;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair rocket:(Rocket *)rocket wildcard:(CCNode *)node
{
	[rocket destroy];
	return NO;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair ship:(PlayerShip *)player pickup:(SpaceBucks *)pickup
{
	[pickup removeFromParent];
	[_pickups removeObject:pickup];
	
	[self drawFlash:pickup.position withImage:pickup.flashImage];
	[[OALSimpleAudio sharedInstance] playEffect:@"TempSounds/Pickup.wav" volume:0.5 pitch:1.0 pan:0.0 loop:NO];
	
	_spaceBucks += [pickup amount];
	levelProgress.percentage = ((float) _spaceBucks/ _spaceBucksTilNextLevel) * 100.0f;
	if(_spaceBucks >= _spaceBucksTilNextLevel){
		[self levelUp];
	}
	
	
	return NO;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair wall:(CCNode *)wall pickup:(SpaceBucks *)pickup
{
	[pickup scheduleBlock:^(CCTimer *timer) {
		[pickup removeFromParent];
		[_pickups removeObject:pickup];
	} delay:1.0f];
	return NO;
}


@end
