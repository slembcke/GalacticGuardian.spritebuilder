#define DefaultsMusicKey @"MusicVolume"
#define DefaultsSoundKey @"SoundVolume"


#define GameSceneSize 1024.0


static NSString * const ship_names[] =			{@"Retribution", @"Defiant", @"Herald"};
static NSString * const ship_fileNames[] =	{@"Retribution", @"ScottSpaceship", @"AndySpaceship"};

typedef NS_ENUM(NSUInteger, ShipType){
	Ship_Retribution, Ship_Defiant, Ship_Herald
};

static const int SpaceBucksTilLevel1 = 30;
static const float SpaceBucksLevelMultiplier = 1.15;

static const float RocketRange = 125.0;

enum Z_ORDER {
	Z_SCROLL_NODE,
	Z_NEBULA,
	Z_PHYSICS,
	Z_SMOKE,
	Z_DEBRIS,
	Z_BULLET,
	Z_ENEMY,
	Z_PLAYER,
	Z_FLASH,
	Z_PICKUPS,
	Z_FIRE,
	Z_RETICLE,
	Z_CONTROLS,
	Z_HUD,
};

#define CollisionCategoryPlayer @"Player"
#define CollisionCategoryEnemy @"Enemy"
#define CollisionCategoryDebris @"Debris"
#define CollisionCategoryBullet @"Bullet"
#define CollisionCategoryAsteroid @"Asteroid"
#define CollisionCategoryBarrier @"Barrier"
#define CollisionCategoryPickup @"Pickup"
