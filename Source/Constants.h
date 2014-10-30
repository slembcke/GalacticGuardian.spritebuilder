#define DefaultsMusicKey @"MusicVolume"
#define DefaultsSoundKey @"SoundVolume"


static CGSize GameSceneSize = {1024, 1024};

typedef NS_ENUM(NSUInteger, ShipTypes){
	Ship_Retribution, Ship_Defiant, Ship_Herald
};

enum Z_ORDER {
	Z_SCROLL_NODE,
	Z_NEBULA,
	Z_PHYSICS,
	Z_BULLET,
	Z_PARTICLES,
	Z_ENEMY,
	Z_PLAYER,
	Z_FLASH,
	Z_DEBRIS,
	Z_PICKUPS,
	Z_CONTROLS,
};

#define CollisionCategoryPlayer @"Player"
#define CollisionCategoryEnemy @"Enemy"
#define CollisionCategoryDebris @"Debris"
#define CollisionCategoryBullet @"Bullet"
#define CollisionCategoryAsteroid @"Asteroid"
#define CollisionCategoryBarrier @"Barrier"
#define CollisionCategoryPickup @"Pickup"
