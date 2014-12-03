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
#import "BurnTransition.h"

#import "CCDirector_Private.h"

@interface GameScene()
@property(nonatomic, assign) int novaBombs;
@property(nonatomic, assign) int spaceBucks;
@property(nonatomic, assign) int level;
@end


@implementation GameScene
{
	CCNode *_scrollNode;
	
	CCPhysicsNode *_physics;
	NebulaBackground *_background;
	
	Controls *_controls;
	CCProgressNode *_rocketReticle;
	
	// HUD elements
	CCLabelTTF *_levelLabel;
	CCLabelTTF *_bombLabel;
	CCNode *_shieldBar;
	CCNode *_moneyBar;
	
	NSMutableArray *_enemies;
	
	CCTime _fixedTime;
	
	int _enemies_killed;
	
	int _shipLevel;
	BulletLevel _bulletLevel;
	RocketLevel _rocketLevel;
	
	int _spaceBucksTilNextLevel;
}

-(instancetype)initWithShipType:(ShipType) shipType
{
	if((self = [super init])){
		CCNode *hud = [CCBReader load:@"HUD" owner:self];
		[self addChild:hud z:Z_HUD];
		
		self.spaceBucks = 0;
        
        if([[NSUserDefaults standardUserDefaults] boolForKey:DefaultsDifficultyHardKey]){
            _spaceBucksTilNextLevel = SpaceBucksTilLevel1HardMode;
        }else{
            _spaceBucksTilNextLevel = SpaceBucksTilLevel1EasyMode;
        }
		
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
		
		_background = [NebulaBackground node];
		_background.contentSize = CGSizeMake(GameSceneSize, GameSceneSize);
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
		CGRect boundsRect = CGRectMake(-boundsWidth, -boundsWidth, GameSceneSize + 2.0*boundsWidth, GameSceneSize + 2.0*boundsWidth);
		bounds.physicsBody = [CCPhysicsBody bodyWithPolylineFromRect:boundsRect cornerRadius:boundsWidth];
		bounds.physicsBody.collisionCategories = @[CollisionCategoryBarrier];
		bounds.physicsBody.collisionMask = @[CollisionCategoryPlayer];
		bounds.physicsBody.elasticity = 1.0;
		[_physics addChild:bounds];
		
		// Add a ship in the middle of the screen.
		[self createPlayerShipAt: ccp(GameSceneSize/2.0, GameSceneSize/2.0) withArt:ship_fileNames[shipType]];
		
		for(int i = 0; i < 15; i++){
			// maybe this spoke/circle pattern will be cool.
			float angle = (M_PI * 2.0f / 15.0f) * i;
			[self addWallAt: ccpAdd(ccpMult(ccpForAngle(angle), 200.0f + 250.0f * CCRANDOM_0_1() ), ccp(512, 512))];
		}
		
		// Enable touch events.
		// The entire scene is used as a shoot button.
		self.userInteractionEnabled = YES;
		
		_enemies = [NSMutableArray array];
		[self setupEnemySpawnTimer];
	}
	
	return self;
}

-(void)dealloc
{
	NSLog(@"Dealloc GameScene.");
}

-(void)setupControls
{
	_controls = [Controls node];
	[self addChild:_controls z:Z_CONTROLS];
	
	// Hide the buttons until you unlock the upgrades.
	_controls.rocketButtonVisible = NO;
	_controls.novaButtonVisible = NO;
	
	__weak typeof(self) _self = self;
	[_controls setHandler:^(BOOL state) {if(state) [_self pause];} forButton:ControlPauseButton];
	[_controls setHandler:^(BOOL state) {if(state) [_self fireRocket];} forButton:ControlRocketButton];
	[_controls setHandler:^(BOOL state) {if(state) [_self fireNovaBomb];} forButton:ControlNovaButton];
}

-(void)addWallAt:(CGPoint) pos
{
	int type = rand()%6;
	
	CCNode *wall = (CCNode *)[CCBReader load:[NSString stringWithFormat:@"Asteroid%d", type]];
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
}

-(void)setScrollPosition:(CGPoint)scrollPosition
{
	float smoothing = 1e3;
	
    CGSize contentSize = self.contentSizeInPoints;

    float clampWidth = (GameSceneSize - contentSize.width)/2.0;
    float clampHeight = (GameSceneSize - contentSize.height)/2.0;
    
	CGPoint exp = CGPointMake(
		(scrollPosition.x - GameSceneSize/2.0)/clampWidth,
		(scrollPosition.y - GameSceneSize/2.0)/clampHeight
	);
	
	CGPoint offset = CGPointMake(
		clampWidth*(log(pow(smoothing, -exp.x - 1.0) + 1.01) - log(pow(smoothing, exp.x - 1.0) + 1.01)),
		clampHeight*(log(pow(smoothing, -exp.y - 1.0) + 1.01) - log(pow(smoothing, exp.y - 1.0) + 1.01))
	);
	
	_scrollNode.anchorPoint = ccpAdd(scrollPosition, ccpMult(offset, 1.0/log(smoothing)));
}

-(void)update:(CCTime)delta
{
	self.scrollPosition = _playerShip.position;
	
	// Update the reticle's position.
	_rocketReticle.position = CGPointApplyAffineTransform(ccp(RocketRange, 0.0), _playerShip.nodeToParentTransform);
}

-(void)enemyDeath:(EnemyShip *)enemy from:(Bullet *) bullet;
{
	[_enemies removeObject:enemy];
	
	if(![_playerShip isDead]){
		_enemies_killed += 1;
	}
	
	CCColor *weaponColor = bullet.bulletColor ?: [CCColor colorWithRed:1.0f green:1.0f blue:0.3f];
	[enemy destroyWithWeaponColor:weaponColor];
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
	Bullet *bullet = [[Bullet alloc] initWithBulletLevel:_bulletLevel];
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
	// Don't fire if out of ammo or the ship is destroyed.
	if(
		_rocketLevel == RocketNone ||
		_rocketReticle.percentage < 100.0 ||
		[_playerShip isDead]
	){
		return;
	}
	
	CGAffineTransform transform = _playerShip.physicsBody.absoluteTransform;
	CGPoint position = ccp(transform.tx, transform.ty);
	CGPoint direction = ccp(transform.a, transform.b);
	
	Rocket *rocket = [Rocket rocketWithLevel:_rocketLevel];
	rocket.position = position;
	rocket.rotation = -CC_RADIANS_TO_DEGREES(ccpToAngle(direction));
	
	// Make the rocket start at the ship's velocity.
	// Let it accelerate itself.
	rocket.physicsBody.velocity = _playerShip.physicsBody.velocity;
	
	[_physics addChild:rocket z:Z_BULLET];
	
	_controls.rocketButtonEnabled = NO;
	
	_rocketReticle.percentage = 0.0;
	_rocketReticle.color = [CCColor whiteColor];
	_rocketReticle.opacity = 0.5;
	
	[self scheduleBlock:^(CCTimer *timer) {
		_rocketReticle.percentage += 10.0;
		
		if(_rocketReticle.percentage == 100.0){
			_controls.rocketButtonEnabled = YES;
			
			_rocketReticle.color = [CCColor redColor];
			_rocketReticle.opacity = 0.5;
		} else {
			[timer repeatOnceWithInterval:0.5];
		}
	} delay:0.5];
}

-(void)fireNovaBomb
{
	// Don't fire if out of ammo or the ship is destroyed.
	if(self.novaBombs == 0 || [_playerShip isDead]) return;
	self.novaBombs -= 1;
	
	[self novaBombAt:_playerPosition];
}

-(void)novaBombAt:(CGPoint)pos
{
	CCParticleSystem *distortion = (CCParticleSystem *)[CCBReader load:@"DistortionParticles/LargeRing"];
	distortion.position = pos;
	[_background.distortionNode addChild:distortion];
	
	[self scheduleBlock:^(CCTimer *timer) {
		[distortion removeFromParent];
	} delay:5.0];
	
	float accel = distortion.radialAccel;
	float limit = distortion.life + distortion.lifeVar;
	
	for (EnemyShip *enemy in _enemies) {
		// explode based on distance from player and particle system values.
		// Things are gnerally moving towards the player, so fudge the numbers a little.
		float dist = MAX(ccpLength(ccpSub(pos, enemy.position)) - 30.0, 0.0);
		float delay = sqrt(2.0*dist/accel);
		
		if(delay < limit){
			[enemy scheduleBlock:^(CCTimer *timer) {[self enemyDeath:enemy from:nil];} delay:delay];
		}
	}
}

static NSArray *DebrisCollisionCategories = nil;

+(void)initialize
{
	if(self != [GameScene class]) return;
	
	DebrisCollisionCategories = @[CollisionCategoryDebris];
}

void
InitDebris(CCNode *root, CCNode *node, CGPoint velocity, CCColor *burnColor)
{
	// If the node has a body, set some properties.
	CCPhysicsBody *body = node.physicsBody;
	body.collisionCategories = DebrisCollisionCategories;
	
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

-(void)pause
{
	CCDirector *director = [CCDirector sharedDirector];
	CGSize viewSize = director.viewSize;
	
	CCScene *pause = (CCScene *)[CCBReader load:@"PauseScene"];
	
	CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:viewSize.width height:viewSize.height];
	
	GLKMatrix4 projection = director.projectionMatrix;
	CCRenderer *renderer = [rt begin];
		[self visit:renderer parentTransform:&projection];
	[rt end];
	
	CCSprite *screenGrab = [CCSprite spriteWithTexture:rt.texture];
	screenGrab.anchorPoint = ccp(0.0, 0.0);
	screenGrab.effect = [CCEffectStack effects:
#if !CC_DIRECTOR_IOS_THREADED_RENDERING
		// BUG!
		[CCEffectBlur effectWithBlurRadius:4.0],
#endif
		[CCEffectSaturation effectWithSaturation:-0.5],
		nil
	];
	[pause addChild:screenGrab z:-1];
	
	[director pushScene:pause withTransition:[CCTransition transitionCrossFadeWithDuration:0.25]];
}

-(void) createPlayerShipAt:(CGPoint) pos withArt:(NSString *) shipArt
{
	float rotation = -90.0f;
	CGPoint velocity = CGPointZero;
	if(_playerShip){
		rotation = _playerShip.rotation;
		velocity = _playerShip.physicsBody.velocity;
		
		[_playerShip removeFromParent];
	}
	
	_playerShip = (PlayerShip *)[CCBReader load:[NSString stringWithFormat:@"%@-%d", shipArt, _shipLevel + 1]];
	_playerShip.position = pos;
	_playerShip.rotation = rotation;
	_playerShip.physicsBody.velocity = velocity;
	_playerShip.name = shipArt;
	[_physics addChild:_playerShip z:Z_PLAYER];
	[_background.distortionNode addChild:_playerShip.shieldDistortionSprite];
	
	[self updateShieldBar];
	
	// Center on the player.
	self.scrollPosition = _playerShip.position;
	
	CCNode *distortion = [CCBReader load:@"DistortionParticles/SmallRing"];
	distortion.position = pos;
	[_background.distortionNode addChild:distortion];
	
	[self scheduleBlock:^(CCTimer *timer) {
		[distortion removeFromParent];
	} delay:5];
}

-(void)levelUpText:(NSString *)text
{
	CCLabelTTF *levelUpText = [CCLabelTTF labelWithString:text fontName:@"kenvector_future.ttf" fontSize:36.0];
	levelUpText.outlineColor =	[CCColor colorWithWhite:0.5f alpha:1.0f];
	levelUpText.color =					[CCColor colorWithWhite:0.8f alpha:1.0f];
	levelUpText.shadowColor =		[CCColor colorWithWhite:0.0f alpha:0.5f];
	levelUpText.shadowBlurRadius = 1.0f;
	levelUpText.shadowOffset = ccp(1.0f, -1.0f);
	
	[self addChild:levelUpText];
	levelUpText.positionType = CCPositionTypeNormalized;
	levelUpText.position = ccp(0.5, 0.5);
	levelUpText.anchorPoint = ccp(0.5, 0.66);
	
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
			[self createPlayerShipAt:_playerShip.position withArt:_playerShip.name];
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
			[self createPlayerShipAt:_playerShip.position withArt:_playerShip.name];
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
	
	[[OALSimpleAudio sharedInstance] playEffect:@"TempSounds/LevelUp.wav" volume:0.8 pitch:1.0 pan:0.0 loop:NO];
}

static CGPoint
RandomGroupPosition(float padding)
{
	// Start with a random direction.
	CGPoint dir = CCRANDOM_ON_UNIT_CIRCLE();
	
	// Project that direction onto a unit square so we can spawn them just outside the screen's bounds.
	dir = ccpMult(dir, 1.0/MAX(fabs(dir.x), fabs(dir.y)));
	
	// Now just need to turn that into an actual location.
	return CGPointMake(
		(0.5 + 0.5*dir.x)*GameSceneSize + dir.x*padding,
		(0.5 + 0.5*dir.y)*GameSceneSize + dir.y*padding
	);
}

// Set up timers to spawn a group of enemies.
-(void)spawnGroup
{
	static NSUInteger spawnCounter = 0;
	NSUInteger maxAllowedEnemies = MIN(10 + _level*3, 40);
	
	NSUInteger MinGroupSize = 3;
	NSUInteger MaxGroupSize = 8;
	
	NSUInteger openSlots = maxAllowedEnemies - _enemies.count;
	if(openSlots < MinGroupSize) return;
	
	NSUInteger groupCount = MinGroupSize + random()%(MaxGroupSize - MinGroupSize);
	groupCount = MIN(groupCount, openSlots);
	
	const float GroupRadius = 100.0;
	CGPoint groupPosition = RandomGroupPosition(GroupRadius);
	
	CCTimer *spawnTimer = [self scheduleBlock:^(CCTimer *timer) {
		NSUInteger bigEnemyProbability = MAX(0, MIN(_level - 10, 5));
		
		BOOL isBig = (bigEnemyProbability > spawnCounter%5);
		EnemyShip *enemy = (EnemyShip *)[CCBReader load:isBig ? @"BadGuy2" : @"BadGuy1"];
		
		enemy.position = ccpAdd(groupPosition, ccpMult(CCRANDOM_IN_UNIT_CIRCLE(), GroupRadius));
		[_physics addChild:enemy z:Z_ENEMY];
		[_enemies addObject:enemy];
		
		spawnCounter++;
	} delay:0.0];
	
	// Configure the timer to repeat to spawn the rest of the enemies too.
	// Scatter the spawn times to avoid frame spikes.
	spawnTimer.repeatInterval = 0.1;
	spawnTimer.repeatCount = groupCount - 1;
}

-(void)setupEnemySpawnTimer
{
	CCTimer *groupSpawnTimer = [self scheduleBlock:^(CCTimer *timer) {
		// Try once per second to add a group of enemies to the game.
		[self spawnGroup];
	} delay:0.0];
	
	// Configure the timer to repeat.
	groupSpawnTimer.repeatInterval = 1.0;
	groupSpawnTimer.repeatCount = CCTimerRepeatForever;
}

-(CCNode *)distortionNode
{
	return _background.distortionNode;
}

static const float MinBarWidth = 5.0;

-(void)setSpaceBucks:(int)spaceBucks
{
	_spaceBucks = spaceBucks;
	
	CGSize size = _moneyBar.parent.contentSize;
	float width = (float)spaceBucks/(float)_spaceBucksTilNextLevel*size.width;
	_moneyBar.contentSize = CGSizeMake(MAX(width, MinBarWidth), size.height);
}

-(void)updateShieldBar
{
	CGSize size = _shieldBar.parent.contentSize;
	float width = _playerShip.health*size.width;
	_shieldBar.contentSize = CGSizeMake(MAX(width, MinBarWidth), size.height);
}

-(void)setNovaBombs:(int)novaBombs
{
	_novaBombs = novaBombs;
	_bombLabel.string = [NSString stringWithFormat:@"Bombs: %d", novaBombs];
	
	_controls.novaButtonVisible = YES;
	_controls.novaButtonEnabled = (novaBombs > 0);
}

-(void)setLevel:(int)level
{
	_level = level;
	_levelLabel.string = [NSString stringWithFormat:@"Level: %d", level + 1];
}


#pragma mark - CCPhysicsCollisionDelegate methods


-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair ship:(PlayerShip *)player enemy:(EnemyShip *)enemy
{
	if([_playerShip takeDamage]){
		[_playerShip destroy];
		
        // slow time:
        [CCDirector sharedDirector].scheduler.timeScale = 0.25f;
        
        // and zoom in on the player?
        [_scrollNode runAction:[CCActionEaseInOut actionWithAction: [CCActionScaleTo actionWithDuration:0.1f scale:1.65f] rate:2.0] ];
        
        [self scheduleBlock:^(CCTimer *timer){
			// Go back to the menu after a short delay.
            [CCDirector sharedDirector].scheduler.timeScale = 1.0f;
			[[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"MainMenu"] withTransition:[BurnTransition burnTransitionWithDuration:1.0]];
		} delay:1.75f];
		
		// Don't process the collision so the enemy spaceship will survive and mock you.
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
	
	[self drawFlash:pickup.position withImage:pickup.flashImage];
	[[OALSimpleAudio sharedInstance] playEffect:@"TempSounds/Pickup.wav" volume:0.25 pitch:1.0 pan:0.0 loop:NO];
	
	self.spaceBucks += [pickup amount];
	if(self.spaceBucks >= _spaceBucksTilNextLevel){
		[self levelUp];
	}
	
	
	return NO;
}

@end
