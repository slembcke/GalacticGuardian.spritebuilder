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
#import "BurnTransition.h"
#import "CCEffectLine.h"
#import "ScoreBoard.h"

#import "CCDirector_Private.h"
#import "CCTexture_Private.h"

#import "CCWwise.h"

@interface GameScene()
@property(nonatomic, assign) int novaBombs;
@property(nonatomic, assign) int spaceBucks;
@property(nonatomic, assign) int level;
@end


@implementation GameScene
{
	// This is the parent node to all of the content on the screen that scrolls around.
	CCNode *_scrollNode;
	
	CCPhysicsNode *_physics;
	NebulaBackground *_background;
	
	Controls *_controls;
	CCProgressNode *_rocketReticle;
	CCSprite *_targetLock;
	CGPoint _rocketLaunchDirection;
	
	// HUD elements
	CCNode *_shieldBar;
	CCNode *_moneyBar;
    ScoreBoard* _scoreBoard;
	
	NSMutableArray *_enemies;
	
	// Time that the most recent fixed update ran at.
	CCTime _fixedTime;
	
	int _shipLevel;
	BulletLevel _bulletLevel;
	RocketLevel _rocketLevel;
	
	int _points;
	int _spaceBucksTilNextLevel;
	
	// This light is recycled for each explosion.
	CCLightNode *_glowLight;
	
	PlayerShip *_playerShip1;
	PlayerShip *_playerShip2;
	
	CCSprite *_linkSprite;
}

-(instancetype)initWithShipType:(ShipType) shipType
{
	if((self = [super init])){

        CCWwise *w = [CCWwise sharedManager];
        [w registerGameObject:self];
        
        [[CCWwise sharedManager] postEvent:@"GameStart" forGameObject:self];

        CCNode *hud = [CCBReader load:@"HUD" owner:self];
		[self addChild:hud z:Z_HUD];
		
		self.spaceBucks = 0;
		_spaceBucksTilNextLevel = SpaceBucksTilLevel1HardMode;
		
		self.level = 0;
		self.spaceBucks = 0;
		self.novaBombs = 0;
				
		[self setupControls];
		
		_scrollNode = [CCNode node];
		_scrollNode.contentSize = CGSizeMake(1.0, 1.0);
		_scrollNode.positionType = CCPositionTypeNormalized;
		_scrollNode.position = ccp(0.5, 0.5);
		[self addChild:_scrollNode z:Z_SCROLL_NODE];
		
		_rocketReticle = [CCProgressNode progressWithSprite:[CCSprite spriteWithImageNamed:@"RocketReticle.png"]];
		_rocketReticle.type = CCProgressNodeTypeRadial;
		_rocketReticle.position = ccp(512, 512);
		[_scrollNode addChild:_rocketReticle z:Z_RETICLE];
		
		_rocketReticle.color = [CCColor redColor];
		_rocketReticle.percentage = 100.0;
		_rocketReticle.visible = NO;
		
		// Make the reticle spin.
		[_rocketReticle runAction:[CCActionRepeatForever actionWithAction:[CCActionRotateBy actionWithDuration:1.0 angle:-360.0]]];
		
		_targetLock = [Rocket lockSprite];
		[_scrollNode addChild:_targetLock z:Z_RETICLE];
		
		_rocketLaunchDirection = cpv(200.0, 200.0);
		
		_background = [NebulaBackground node];
		_background.contentSize = CGSizeMake(GameSceneSize, GameSceneSize);
		[_scrollNode addChild:_background z:Z_NEBULA];
		
		_physics = [CCPhysicsNode node];
		[_scrollNode addChild:_physics z:Z_PHYSICS];
		
		// Reduce the physics collision quality to save CPU time.
		_physics.iterations = 1;
		
		// Use the gamescene as the collision delegate.
		// See the ccPhysicsCollision* methods below.
		_physics.collisionDelegate = self;
		
		// Enable to show debug outlines for Physics shapes.
//		_physics.debugDraw = YES;
		
		// Set up a box around the screen that only the player collides with.
		// This keeps the player in the game area while allowing enemies to enter.
		CCNode *bounds = [CCNode node];
		CGFloat boundsWidth = 50.0;
		CGRect boundsRect = CGRectMake(-boundsWidth, -boundsWidth, GameSceneSize + 2.0*boundsWidth, GameSceneSize + 2.0*boundsWidth);
		bounds.physicsBody = [CCPhysicsBody bodyWithPolylineFromRect:boundsRect cornerRadius:boundsWidth];
		bounds.physicsBody.collisionCategories = @[CollisionCategoryBarrier];
		bounds.physicsBody.collisionMask = @[CollisionCategoryPlayer];
		bounds.physicsBody.elasticity = 1.0;
		[_physics addChild:bounds];
		
		// Make a random, circular-ish pattern of asteroids.
		for(int i = 0; i < 15; i++){
			float angle = (M_PI * 2.0f / 15.0f) * i;
			int type = rand()%6;
			
			CCNode *asteroid = (CCNode *)[CCBReader load:[NSString stringWithFormat:@"Asteroid%d", type]];
			asteroid.position = ccpAdd(ccpMult(ccpForAngle(angle), 200.0f + 250.0f * CCRANDOM_0_1()), ccp(GameSceneSize/2.0, GameSceneSize/2.0));
			asteroid.rotation = CCRANDOM_0_1() * 360.0f;
			[_physics addChild:asteroid z:Z_ENEMY];
			
			[asteroid runAction:[CCActionRepeatForever actionWithAction:[CCActionRotateBy actionWithDuration:1.0 angle:45.0*CCRANDOM_MINUS1_1()]]];
		}
		
		_enemies = [NSMutableArray array];
		[self setupEnemySpawnTimer];
		
		// Setup the global light.
		CCLightNode *light = [CCLightNode lightWithType:CCLightPoint groups:nil color:[CCColor whiteColor] intensity:1.0];
        light.type = CCLightDirectional;
        light.rotation = -45;
		light.ambientIntensity = 0.2;
		light.depth = 1;
		[_scrollNode addChild:light];
		
		_glowLight = [CCLightNode lightWithType:CCLightPoint groups:nil color:[CCColor whiteColor] intensity:0.0];
		_glowLight.ambientIntensity = 0.0;
		_glowLight.cutoffRadius = GameSceneSize;
		_glowLight.halfRadius = 0.1;
		_glowLight.depth = 0;
		[_scrollNode addChild:_glowLight];
		
		// Skip to level 6 in demo mode.
		if(!([[NSUserDefaults standardUserDefaults] boolForKey:DefaultsDifficultyHardKey])){
			self.level = 5;
			
			_spaceBucksTilNextLevel *= pow(SpaceBucksLevelMultiplier, 5.0);
			
			_bulletLevel = 2;
			self.novaBombs += 2;
			
			_rocketLevel = 1;
			_controls.rocketButtonVisible = YES;
			_rocketReticle.visible = YES;
			
			_shipLevel = 1;
		}
		
		// Add the player's ship in the center of the game area.
		_playerShip1 = [self replacePlayerShip:nil position:ccp(GameSceneSize/2.0, GameSceneSize/2.0) withArt:ship_fileNames[shipType] shipIndex:0];
		
		// Pump the update loop once to set the rocket reticle position._
		[self update:0.0];
	}
	
	return self;
}

-(void)dealloc
{
	CCLOG(@"Dealloc GameScene.");
}

-(void)setupControls
{
	_controls = [Controls node];
	[self addChild:_controls z:Z_CONTROLS];
	
	// Hide the buttons until you unlock the upgrades.
	_controls.rocketButtonVisible = NO;
	
	__weak typeof(self) _self = self;
	[_controls setHandler:^(BOOL state) {if(state) [_self pause];} forButton:ControlPauseButton];
	[_controls setHandler:^(BOOL state) {if(state) [_self joinPlayer2];} forButton:ControlJoinButton];
	[_controls setHandler:^(BOOL state) {if(state) [_self fireNovaBomb];} forButton:ControlNovaButton];
}

-(void)fixedUpdate:(CCTime)delta
{
	_fixedTime += delta;
	
	// Send the joystick input to the ship.
	[_playerShip1 ggFixedUpdate:delta withControls:_controls index:0];
	
	if(_playerShip2){
		[_playerShip2 ggFixedUpdate:delta withControls:_controls index:1];
		
		_playerPosition = ccpLerp(_playerShip1.position, _playerShip2.position, 0.5);
	} else {
		_playerPosition = _playerShip1.position;
	}
	
	if(ccpLength(_controls.aimDirection1) > 0.25){
		if(_playerShip1.lastFireTime + (1.0f / _playerShip1.fireRate) < _fixedTime){
			[self fireBullet:_playerShip1];
		}
	}
	
	if(ccpLength(_controls.aimDirection2) > 0.25){
		if(_playerShip2.lastFireTime + (1.0f / _playerShip2.fireRate) < _fixedTime){
			[self fireBullet:_playerShip2];
		}
	}
}

-(void)setScrollPosition:(CGPoint)scrollPosition
{
	float smoothing = 1e3;
	
	CGSize contentSize = CC_SIZE_SCALE(self.contentSizeInPoints, 1.0/_scrollNode.scale);
	
	float clampWidth = (GameSceneSize - contentSize.width)/2.0;
	float clampHeight = (GameSceneSize - contentSize.height)/2.0;
	
	CGPoint exp = CGPointMake(
		(scrollPosition.x - GameSceneSize/2.0)/clampWidth,
		(scrollPosition.y - GameSceneSize/2.0)/clampHeight
	);
	
	// Admittedly this is an overcomplicated way to smoothly clamp the screen to the game area.
	// I was having fun with math...
	CGPoint offset = CGPointMake(
		clampWidth*(log(pow(smoothing, -exp.x - 1.0) + 1.01) - log(pow(smoothing, exp.x - 1.0) + 1.01)),
		clampHeight*(log(pow(smoothing, -exp.y - 1.0) + 1.01) - log(pow(smoothing, exp.y - 1.0) + 1.01))
	);
	
	_scrollNode.anchorPoint = ccpAdd(scrollPosition, ccpMult(offset, 1.0/log(smoothing)));
}

-(CGPoint)rocketAim:(PlayerShip *)playerShip
{
	return CGPointApplyAffineTransform(ccp(RocketRange, 0.0), playerShip.nodeToParentTransform);
}

-(EnemyShip *)rocketTarget:(CGPoint)aim limit:(float)limit;
{
	EnemyShip *target = nil;
	float closestDist = limit;
	for(EnemyShip *enemy in _enemies){
		float dist = ccpDistance(aim, enemy.position);
		if(dist < closestDist){
			target = enemy;
			closestDist = dist;
		}
	}
	
	return target;
}

const float RocketAimLimit = 75.0f;

-(void)update:(CCTime)delta
{
	self.scrollPosition = _playerPosition;
	
	// TODO
	// Update the reticle's position.
	CGPoint aim = [self rocketAim:_playerShip1];
	_rocketReticle.position = aim;
	
	EnemyShip *target = [self rocketTarget:aim limit:RocketAimLimit];
	if(target){
		_targetLock.position = target.position;
		_targetLock.visible = YES;
	} else {
		_targetLock.visible = NO;
	}

	if(!_playerShip1.isDead){
		CCScheduler *scheduler = [CCDirector sharedDirector].scheduler;
		scheduler.timeScale = cpflerpconst(scheduler.timeScale, 1.0, 0.25*delta);
        [[CCWwise sharedManager] setRTPCValue:@"TimeScale" to:scheduler.timeScale];
	}
	
	if(_linkSprite){
		CGPoint pos = _playerShip1.position;
		CGPoint dir = ccpSub(_playerShip2.position, pos);
		
		_linkSprite.position = pos;
		_linkSprite.rotation = -CC_RADIANS_TO_DEGREES(ccpToAngle(dir));
		_linkSprite.scaleX = ccpLength(dir)/_linkSprite.contentSize.width;
		
		CGRect rect = _linkSprite.textureRect;
		rect.origin.x = CCRANDOM_0_1()*rect.size.width;
		_linkSprite.textureRect = rect;
	}
}

-(void)enemyDeath:(EnemyShip *)enemy from:(Bullet *) bullet;
{
	[_enemies removeObject:enemy];
	
	// Set color of the burn animation for the enemy's debris to match the bullet that killed it.
	CCColor *weaponColor = bullet.bulletColor ?: [CCColor colorWithRed:1.0f green:1.0f blue:0.3f];
	[enemy destroyWithWeaponColor:weaponColor];
}

-(void)splashDamageAt:(CGPoint)center radius:(float)radius damage:(int)damage;
{
    
    [[CCWwise sharedManager] postEvent:@"PlayerRocketExplode" forGameObject:self];
    
	// Iterate a copy of the array since enemies can be destroyed inside the loop.
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
	
	// Set up the flash sprite and it's animation.
    if (imagePath)
    {
        CCSprite *flash = [CCSprite spriteWithImageNamed:imagePath];
        flash.position = position;
        flash.rotation = 360.0*CCRANDOM_0_1();
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
    }
	
	// Draw some distortion to use with it.
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

-(void)drawGlow:(CGPoint)position scale:(float)scale;
{
	float duration = scale/5.0;
	CCColor *color = [CCColor whiteColor];
	
	[self glowLight:position intensity:2*scale duration:duration];
	
	CCSprite *glow = [CCSprite spriteWithImageNamed:@"Sprites/LensFlare.png"];
	glow.position = position;
	glow.scale = scale;
	glow.color = color;
	glow.opacity = 0.9;
	glow.blendMode = [CCBlendMode addMode];
	[_scrollNode addChild:glow z:Z_FIRE];
	
	[glow runAction:[CCActionSequence actions:
		[CCActionScaleTo actionWithDuration:duration scale:glow.scale/2.0],
		[CCActionFadeOut actionWithDuration:duration/2],
		[CCActionRemove action],
		nil
	]];
	
	float flareOffset = scale*30.0;
	
	CCSprite *flareLeft = [CCSprite spriteWithImageNamed:@"Sprites/LensFlareSide.png"];
	flareLeft.position = ccp(position.x - flareOffset, position.y);
	flareLeft.scale = scale;
	flareLeft.color = color;
	flareLeft.blendMode = [CCBlendMode addMode];
	[_scrollNode addChild:flareLeft z:Z_FIRE];
	
	[flareLeft runAction:[CCActionSequence actions:
		[CCActionFadeTo actionWithDuration:duration],
		[CCActionRemove action],
		nil
	]];
	
	CCSprite *flareRight = [CCSprite spriteWithImageNamed:@"Sprites/LensFlareSide.png"];
	flareRight.position = ccp(position.x + flareOffset, position.y);
	flareRight.scale = scale;
	flareRight.flipX = YES;
	flareRight.color = color;
	flareRight.blendMode = [CCBlendMode addMode];
	[_scrollNode addChild:flareRight z:Z_FIRE];
	
	[flareRight runAction:[CCActionSequence actions:
		[CCActionFadeTo actionWithDuration:duration],
		[CCActionRemove action],
		nil
	]];
}

-(void)glowLight:(CGPoint)position intensity:(float)intensity duration:(float)duration
{
	// Give priority to brighter effects since we can only afford one light for this.
	if(intensity > _glowLight.intensity){
		_glowLight.position = position;
		
		[_glowLight stopAllActions];
		[_glowLight runAction:[CCActionTween actionWithDuration:duration key:@"intensity" from:intensity to:0.0]];
		[_glowLight runAction:[CCActionTween actionWithDuration:duration key:@"specularIntensity" from:intensity to:0.0]];
	}
}

-(void)fireBullet:(PlayerShip *)playerShip
{
	// Don't fire bullets if the ship is destroyed.
	if([playerShip isDead]) return;
	
	// TODO
	playerShip.lastFireTime = _fixedTime;
	
	// This is sort of a fancy math way to figure out where to fire the bullet from.
	// You could figure this out with more code, but I wanted to have fun with some maths.
	// This gets the transform of one of the "gunports" that I marked in the CCB file with a special node.
	CGAffineTransform transform = playerShip.gunPortTransform;
	
	// An affine transform looks like this when written as a matrix:
	// | a, c, tx |
	// | b, d, ty |
	// The first column, (a, b), is the direction the new x-axis will point after applying the transformation.
	// The second column, (c, d), is the direction the new y-axis will point.
	// The last column, (tx, ty), is the location of the origin after applying the transform.
	
	// So the position of the gunport is just the matrix's origin point (tx, ty).
	CGPoint position = ccp(transform.tx, transform.ty);

	// The node's in the CCB file point along the x-axis.
	// That means the direction the gun is pointing is the first column of the matrix.
	CGPoint direction = ccp(transform.a, transform.b);
	
	// So by "fancy math" I really just meant knowing what the numbers in a CGAffineTransform are. ;)
	// All we had to do was copy the values we wanted out.
	
	// Now we can create the bullet with the position and direction.
	// The bullet sprite points along the y-axis, so we need to rotate by 90 degrees.
	Bullet *bullet = [[Bullet alloc] initWithBulletLevel:_bulletLevel];
	bullet.position = position;
	bullet.rotation = 90.0f - CC_RADIANS_TO_DEGREES(ccpToAngle(direction));
	
	// Make the bullet move in the direction it's pointed.
	bullet.physicsBody.velocity = ccpMult(direction, bullet.speed);
	
	[_physics addChild:bullet z:Z_BULLET];
	
	[playerShip bulletFlash:bullet.bulletColor];
	
	// Make some noise. Add a little chromatically tuned pitch bending to make it sound more musical.
//	int half_steps = (arc4random()%(2*4 + 1) - 4);
//	float pitch = pow(2.0f, half_steps/12.0f);
    [[CCWwise sharedManager] postEvent:@"PlayerFireBullet" forGameObject:self];
	
	if(_rocketReticle.percentage == 100.0){
		[self fireRocket:playerShip];
	}
}

-(void)fireRocket:(PlayerShip *)playerShip
{
    EnemyShip *target = [self rocketTarget:[self rocketAim:playerShip] limit:RocketAimLimit];
	
	if(
		target == nil ||
		// Don't fire until the player unlocks rockets.
		_rocketLevel == RocketNone ||
		// Don't fire until the missile timer is ready.
		_rocketReticle.percentage < 100.0 ||
		// don't fire if the player is dead.
		[playerShip isDead]
	){
		return;
	}
	
	// Apply the same transform trick used in the bullet firing method.
	CGAffineTransform transform = playerShip.physicsBody.absoluteTransform;
	CGPoint position = ccp(transform.tx, transform.ty);
	CGPoint direction = ccp(transform.a, transform.b);
	
	Rocket *rocket = [Rocket rocketWithLevel:_rocketLevel target:target];
	rocket.position = position;
	rocket.rotation = -CC_RADIANS_TO_DEGREES(ccpToAngle(direction));
	
	CCPhysicsBody *player = playerShip.physicsBody;
	_rocketLaunchDirection.y *= -1.0;
	rocket.physicsBody.velocity = cpvadd(player.velocity, cpTransformVect(player.absoluteTransform, _rocketLaunchDirection));
	
	[_physics addChild:rocket z:Z_BULLET];
    [_physics addChild:rocket.trail z:Z_BULLET];
	
	// Disable the rocket button and reset the charging reticle.
	_controls.rocketButtonEnabled = NO;
	
	_rocketReticle.percentage = 0.0;
	_rocketReticle.color = [CCColor whiteColor];
	_rocketReticle.opacity = 0.5;
	
    [[CCWwise sharedManager] postEvent:@"PlayerFiredRocket" forGameObject:self];
    
	// Use a timer to charge the reticle.
	[self scheduleBlock:^(CCTimer *timer) {
		_rocketReticle.percentage += 20.0;
		
		if(_rocketReticle.percentage == 100.0){
			// Reenable the button and reticle when done charging.
			_controls.rocketButtonEnabled = YES;
			
			_rocketReticle.color = [CCColor redColor];
			_rocketReticle.opacity = 0.5;
		} else {
			// Schedule the timer to run again if it's not done charging.
			[timer repeatOnceWithInterval:0.5];
		}
	} delay:0.5];
}

-(void)fireNovaBomb
{
	// Don't fire if out of ammo or the ship is destroyed.
	if(self.novaBombs == 0 || [_playerShip1 isDead]) return;
	self.novaBombs -= 1;
	
    [[CCWwise sharedManager] postEvent:@"PlayerDropNovaBomb" forGameObject:self];
    
	[self novaBombAt:_playerPosition];
}

-(void)novaBombAt:(CGPoint)pos
{
    
	CCParticleSystem *distortion = (CCParticleSystem *)[CCBReader load:@"DistortionParticles/LargeRing"];
	distortion.position = pos;
	[_background.distortionNode addChild:distortion];
	
	[self drawGlow:pos scale:7.0];
	
	const int repeats = 20;
	CCTimer *timer = [self scheduleBlock:^(CCTimer *timer) {
		NSUInteger count = timer.repeatCount;
		float t = 1.0 - (float)count/(float)repeats;
//		NSLog(@"t: %f", t);
		
		float dist = cpflerp(distortion.startRadius, distortion.endRadius, t);
		
		for (EnemyShip *enemy in _enemies) {
			if(ccpDistance(pos, enemy.position) < dist){
				[self scheduleBlock:^(CCTimer *timer) {[self enemyDeath:enemy from:nil];} delay:0.0];
			}
		}
		
		if(count == 0) [distortion removeFromParent];
	} delay:0.0];
	
	timer.repeatCount = repeats;
	timer.repeatInterval = distortion.life/repeats;
	
	[CCDirector sharedDirector].scheduler.timeScale = 0.25;
    [[CCWwise sharedManager] setRTPCValue:@"TimeScale" to:0.25f];
}

static NSArray *DebrisCollisionCategories = nil;

+(void)initialize
{
	if(self != [GameScene class]) return;
	
	// Initialize this array when the class loads so it doesn't have to be re-created every time a piece of debris is created.
	DebrisCollisionCategories = @[CollisionCategoryDebris];
}

void
InitDebris(CCNode *root, CCNode *node, CGPoint velocity, CCColor *burnColor)
{
	// If the node has a body, set some properties.
	CCPhysicsBody *body = node.physicsBody;
	if(body){
		body.collisionCategories = DebrisCollisionCategories;
		
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
		
		// Fade out and destroy the debris after a short random delay.
		[node scheduleBlock:^(CCTimer *timer) {
			[node runAction: [CCActionSequence actions:
			 [CCActionFadeOut actionWithDuration:0.75],
			 [CCActionRemove action],
			 nil
			]];
		} delay:0.5 + 0.5*CCRANDOM_0_1()];
	}
	
	// Recurse on the children.
	for(CCNode *child in node.children) InitDebris(root, child, velocity, burnColor);
}

// Called when the pause button is pressed.
-(void)pause
{
	CCDirector *director = [CCDirector sharedDirector];
	CGSize viewSize = director.viewSize;
	
	CCScene *pause = (CCScene *)[CCBReader load:@"PauseScene"];
	
	CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:viewSize.width height:viewSize.height];
	
	// Use the director's projection to render into the texture as though it were the screen.
	// When this texture is stretched to screen size, it will look the same.
	GLKMatrix4 projection = director.projectionMatrix;
	CCRenderer *renderer = [rt begin];
		[self visit:renderer parentTransform:&projection];
	[rt end];
	
	CCSprite *screenGrab = [CCSprite spriteWithTexture:rt.texture];
	screenGrab.anchorPoint = ccp(0.0, 0.0);
	screenGrab.effect = [CCEffectStack effects:
#if !CC_DIRECTOR_IOS_THREADED_RENDERING
		// TODO MT BUG in the blur effect!
		[CCEffectBlur effectWithBlurRadius:4.0],
#endif
		[CCEffectSaturation effectWithSaturation:-0.5],
		nil
	];
	
	// Add the screen grab sprite to the bottom of the pause screen.
	[pause addChild:screenGrab z:-1];
	
	[director pushScene:pause withTransition:[CCTransition transitionCrossFadeWithDuration:0.25]];
}

static const float PLAYER_MAX_DIST = 75;

-(void)joinPlayer2
{
	if(_playerShip2) return;
	
	CGPoint pos = ccpAdd(_playerShip1.position, ccp(PLAYER_MAX_DIST, 0.0));
	_playerShip2 = [self replacePlayerShip:nil position:pos withArt:_playerShip1.name shipIndex:1];
	[self connectShips];
    
    [[CCWwise sharedManager] postEvent:@"SecondPlayerJoined" forGameObject:self];

}

-(void)connectShips
{
	if(_playerShip2 == nil) return;
	
	// TODO hack to make this work.
	// It happens inside a collision callback and there is a deferral bug.
	[self scheduleBlock:^(CCTimer *timer) {
		[CCPhysicsJoint
			connectedDistanceJointWithBodyA:_playerShip1.physicsBody bodyB:_playerShip2.physicsBody
			anchorA:CGPointZero anchorB:CGPointZero
			minDistance:5 maxDistance:PLAYER_MAX_DIST
		];
		
		[CCPhysicsJoint
			connectedSpringJointWithBodyA:_playerShip1.physicsBody bodyB:_playerShip2.physicsBody
			anchorA:CGPointZero anchorB:CGPointZero
			restLength:PLAYER_MAX_DIST*0.5 stiffness:20 damping:2
		];
	} delay:0.0];
	
	if(_linkSprite == nil){
		CCTexture *electric = [CCTexture textureWithFile:@"electric.png"];
		[electric setTexParameters:(ccTexParams[]){GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT}];
		
		_linkSprite = [CCSprite spriteWithTexture:electric];
		_linkSprite.blendMode = [CCBlendMode addMode];
		_linkSprite.anchorPoint = ccp(0.0, 0.5);
		[_physics addChild:_linkSprite z:Z_LINK];
	}
}

-(PlayerShip *)replacePlayerShip:(PlayerShip *)ship position:(CGPoint)pos withArt:(NSString *)shipArt shipIndex:(NSUInteger)index
{
	// Terrible lazy hack...
	if(shipArt == nil) return nil;
	
	float rotation = -90.0f;
	CGPoint velocity = CGPointZero;
	if(ship){
		rotation = ship.rotation;
		velocity = ship.physicsBody.velocity;
		
		[ship removeFromParent];
	}
	
	PlayerShip *playerShip = (PlayerShip *)[CCBReader load:[NSString stringWithFormat:@"%@-%d", shipArt, _shipLevel + 1]];
	playerShip.position = pos;
	playerShip.rotation = rotation;
	playerShip.physicsBody.velocity = velocity;
	playerShip.name = shipArt;
	[_physics addChild:playerShip z:Z_PLAYER];
	[_background.distortionNode addChild:playerShip.shieldDistortionSprite];
	
	[self updateShieldBar];
	
	// Center the screen on the player.
	self.scrollPosition = playerShip.position;
	
	// Warp the space aronud the player as they appear.
	CCNode *distortion = [CCBReader load:@"DistortionParticles/SmallRing"];
	distortion.position = pos;
	[_background.distortionNode addChild:distortion];
	
	[self scheduleBlock:^(CCTimer *timer) {
		[distortion removeFromParent];
	} delay:5];
	
	if(index == 1){
		CCEffectHue *hue = (CCEffectHue *)[(CCEffectStack *)playerShip.sprite.effect effectAtIndex:0];
		hue.hue = 120.0;
	}
	
	return playerShip;
}

-(void)levelUpText:(NSString *)text
{
    CCLabelBMFont*levelUpText = [CCLabelBMFont labelWithString:[text uppercaseString] fntFile:@"Fonts/GG.bmfont/GG.fnt"];
	
	[self addChild:levelUpText];
	levelUpText.positionType = CCPositionTypeNormalized;
	levelUpText.position = ccp(0.5, 0.618);
	levelUpText.anchorPoint = ccp(0.5, 0.5);
	
	[levelUpText setScale:2.0f];
	[levelUpText runAction:[CCActionSequence actions:
			[CCActionSpawn actions:
				[CCActionFadeIn actionWithDuration:0.15],
				[CCActionScaleTo actionWithDuration:0.25 scale:1.0],
				nil
			],
			[CCActionDelay actionWithDuration:0.95],
			[CCActionSpawn actions:
				[CCActionFadeOut actionWithDuration:0.35],
				[CCActionScaleTo actionWithDuration:0.35 scale:1.5],
				nil
			],
			[CCActionRemove action],
			nil
	]];
}

-(void) levelUp;
{
	self.level += 1;
	self.spaceBucks -= _spaceBucksTilNextLevel;
	_spaceBucksTilNextLevel *= SpaceBucksLevelMultiplier;
	
	switch(self.level){
		case  1: // Bullet1
			_bulletLevel += 1;
			[self levelUpText:@"Laser Level 2"];
			break;
		case  2:// Nova Bomb
			self.novaBombs += 1;
			[self levelUpText:@"Nova Bomb"];
			break;
		case  3:// Bullet 2
			_bulletLevel += 1;
			[self levelUpText:@"Laser Level 3"];
			break;
		case  4:// Rocket 0
			_rocketLevel += 1;
			[self levelUpText:@"Rockets"];
			_controls.rocketButtonVisible = YES;
			_rocketReticle.visible = YES;
			break;
		case  5:// Ship 2
			_shipLevel += 1;
			_playerShip1 = [self replacePlayerShip:_playerShip1 position:_playerShip1.position withArt:_playerShip1.name shipIndex:0];
			_playerShip2 = [self replacePlayerShip:_playerShip2 position:_playerShip2.position withArt:_playerShip2.name shipIndex:1];
			[self connectShips];
			[self levelUpText:@"Ship Level 2"];
			break;
		case  6:// Nova Bomb
			self.novaBombs += 1;
			[self levelUpText:@"Nova Bomb"];
			break;
		case  7:// Bullet 3
			_bulletLevel += 1;
			[self levelUpText:@"Laser Level 4"];
			break;
		case  8://Nova Bomb
			self.novaBombs += 1;
			[self levelUpText:@"Nova Bomb"];
			break;
		case  9://Heavy Rocket
			_rocketLevel += 1;
			[self levelUpText:@"Heavy Rockets"];
			break;
		case 10://Ship 3
			_shipLevel += 1;
			_playerShip1 = [self replacePlayerShip:_playerShip1 position:_playerShip1.position withArt:_playerShip1.name shipIndex:0];
			_playerShip2 = [self replacePlayerShip:_playerShip2 position:_playerShip2.position withArt:_playerShip2.name shipIndex:1];
			[self connectShips];
			[self levelUpText:@"Ship Level 3"];
			break;
		case 11://Bullet 4
			_bulletLevel += 1;
			[self levelUpText:@"Laser Level 5"];
			break;
		case 12://Nova Bomb
			self.novaBombs += 1;
			[self levelUpText:@"Nova Bomb"];
			break;
		case 13://Bullet 5
			_bulletLevel += 1;
			[self levelUpText:@"Laser Level 6"];
			break;
		case 14://Rocket 3
			_rocketLevel += 1;
			[self levelUpText:@"Cluster Rockets"];
			break;
		default: // Nova Bomb forever.
			self.novaBombs += 1;
			[self levelUpText:@"Nova Bomb"];
			break;
	}
	
    [[CCWwise sharedManager] postEvent:@"LevelUp" forGameObject:self];

}

// Find a random position just outside the game area's bounds to spawn a group of enemies.
static CGPoint
RandomGroupPosition(float padding)
{
	// Start with a random direction.
	CGPoint dir = CCRANDOM_ON_UNIT_CIRCLE();
	
	// Project that direction onto a unit square so we can spawn them just outside the screen's bounds.
	dir = ccpMult(dir, 1.0/MAX(fabs(dir.x), fabs(dir.y)));
	
	// Now just need to stretch that square onto the game area's bounds.
	return CGPointMake(
		(0.5 + 0.5*dir.x)*GameSceneSize + dir.x*padding,
		(0.5 + 0.5*dir.y)*GameSceneSize + dir.y*padding
	);
}

static NSMutableDictionary *OBJECT_POOL = nil;

-(id)getPooledObjectForKey:(NSString *)key create:(id<Poolable> (^)(void))block
{
	if(OBJECT_POOL == nil){
		OBJECT_POOL = [NSMutableDictionary dictionary];
	}
	
	NSMutableArray *pool = OBJECT_POOL[key];
	if(pool == nil){
		pool = [NSMutableArray array];
		OBJECT_POOL[key] = pool;
	}
	
	id<Poolable> obj = pool.lastObject;
	if(obj){
		[pool removeLastObject];
		[obj reset];
	} else {
		obj = block();
		obj.poolKey = key;
	}
	
	return obj;
}

-(EnemyShip *)spawnEnemy:(NSString *)name
{
	return [self getPooledObjectForKey:name create:^id<Poolable>{
		return (EnemyShip *)[CCBReader load:name];
	}];
}

-(void)poolObject:(id<Poolable>)obj
{
	[OBJECT_POOL[obj.poolKey] addObject:obj];
}

// Set up a timer to spawn a group of enemies.
-(void)spawnGroup
{
	static NSUInteger spawnCounter = 0;
	NSUInteger maxAllowedEnemies = MIN(20 + _level*4, 60);
	
	if(_playerShip2) maxAllowedEnemies *= 2;
	
	NSUInteger MinGroupSize = 3;
	NSUInteger MaxGroupSize = 8;
	
	NSUInteger openSlots = maxAllowedEnemies - _enemies.count;
	if(openSlots < MinGroupSize) return;
	
	NSUInteger groupCount = MinGroupSize + random()%(MaxGroupSize - MinGroupSize);
	groupCount = MIN(groupCount, openSlots);
	
	const float GroupRadius = 100.0;
	CGPoint groupPosition = RandomGroupPosition(GroupRadius);
	
	CCTimer *spawnTimer = [self scheduleBlock:^(CCTimer *timer) {
		NSUInteger bigEnemyProbability = MAX(0, MIN((_level - 6)/3, 5));
		
		BOOL isBig = (bigEnemyProbability > spawnCounter%10);
		NSString *name = isBig ? @"BadGuy2" : @"BadGuy1";
		EnemyShip *enemy = [self spawnEnemy:name];
		
		enemy.position = ccpAdd(groupPosition, ccpMult(CCRANDOM_IN_UNIT_CIRCLE(), GroupRadius));
		[_physics addChild:enemy z:Z_ENEMY];
		[_enemies addObject:enemy];
		
		spawnCounter++;
	} delay:0.0];
	
	// Configure the timer to repeat to spawn the rest of the enemies too.
	// Scatter the spawn times to avoid doing too much work in a single frame.
	spawnTimer.repeatInterval = 0.1;
	spawnTimer.repeatCount = groupCount - 1;
}

-(void)setupEnemySpawnTimer
{
	CCTimer *groupSpawnTimer = [self scheduleBlock:^(CCTimer *timer) {
		// Try once per second to add a group of enemies to the game.
		[self spawnGroup];
	} delay:0.0];
	
	// Configure the timer to repeat endlessly.
	groupSpawnTimer.repeatInterval = 1.0;
	groupSpawnTimer.repeatCount = CCTimerRepeatForever;
}

-(float)pitchScale
{
	return powf([CCDirector sharedDirector].scheduler.timeScale, 0.20);
}

-(CCNode *)distortionNode
{
	return _background.distortionNode;
}

static const float MinBarWidth = 8.0;
static const float MaxBarWidth = 80.0;

-(void)setSpaceBucks:(int)spaceBucks
{
	_spaceBucks = spaceBucks;
    
    float width = (float)spaceBucks/(float)_spaceBucksTilNextLevel*MaxBarWidth;
    float height = _moneyBar.contentSize.height;
    
    if (width > MaxBarWidth) width = MaxBarWidth;
    
    _moneyBar.contentSize = CGSizeMake(width, height);
    _moneyBar.visible = (width >= MinBarWidth);
}

-(void)updateShieldBar
{
    float width = _playerShip1.health*MaxBarWidth;
    float height = _shieldBar.contentSize.height;
    
    if (width > MaxBarWidth) width = MaxBarWidth;
    
    _shieldBar.contentSize = CGSizeMake(width, height);
    _shieldBar.visible = (width >= MinBarWidth);
}

-(void)setNovaBombs:(int)novaBombs
{
	_novaBombs = novaBombs;
    
    [_controls setNovaBombs:novaBombs];
}

-(void)setLevel:(int)level
{
	_level = level;
//	_levelLabel.string = [NSString stringWithFormat:@"Level: %d", level + 1];
}

//MARK: - CCPhysicsCollisionDelegate methods

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair ship:(PlayerShip *)player enemy:(EnemyShip *)enemy
{
	if([_playerShip1 takeDamage]){
		[_playerShip1 destroy];
		[_playerShip2 destroy];
		
		// and zoom in on the player?
		[_scrollNode runAction:[CCActionEaseInOut actionWithAction: [CCActionScaleTo actionWithDuration:0.1f scale:1.65f] rate:2.0] ];
		
		[self scheduleBlock:^(CCTimer *timer){
			// Go to 'Made with SB' scene
			BurnTransition* transition = [BurnTransition burnTransitionWithDuration:0.5];
#if __CC_PLATFORM_MAC
			// *Way* to expensive on iOS. Causes a lot of stuttering.
			transition.outgoingSceneAnimated = YES;
#endif
			[[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Interstitial/MadeWithSB"] withTransition:transition];
		} delay:1.75f];
		
		return NO;
	}else{
		[self updateShieldBar];
		
		// Player took damage, the enemy should self destruct.
		[self enemyDeath: enemy from:nil];
 
		return YES;
	}
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair bullet:(Bullet *)bullet enemy:(EnemyShip *)enemy
{
	[bullet destroy];
	
    [[CCWwise sharedManager] postEvent:@"PlayerBulletHitEnemy" forGameObject:self];

	if([enemy takeDamage:1]){
		[self enemyDeath:enemy from:bullet];
	}
	
	return NO;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair bullet:(Bullet *)bullet asteroid:(CCNode *)asteroid
{
    [[CCWwise sharedManager] postEvent:@"PlayerBulletAsteroid" forGameObject:self];

	[bullet destroy];
	return NO;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair rocket:(Rocket *)rocket wildcard:(CCNode *)node
{
    [[CCWwise sharedManager] postEvent:@"PlayerBulletHitOther" forGameObject:self];

	[rocket destroy];
	return NO;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair ship:(PlayerShip *)player pickup:(SpaceBucks *)pickup
{
	[pickup removeFromParent];
	
	[self drawFlash:pickup.position withImage:pickup.flashImage];
    [[CCWwise sharedManager] postEvent:@"Pickup" forGameObject:self];
	
	int amount = [pickup amount];
	_points += amount;
	_scoreBoard.score = _points;
	
	self.spaceBucks += amount;
	if(self.spaceBucks >= _spaceBucksTilNextLevel){
		[self levelUp];
	}
	
	return NO;
}

@end
