#define DefaultsMusicKey @"MusicVolume"
#define DefaultsSoundKey @"SoundVolume"


static CGSize GameSceneSize = {1024, 1024};


enum Z_ORDER {
	Z_SCROLL_NODE,
	Z_NEBULA,
	Z_PHYSICS,
	Z_ENEMY,
	Z_PLAYER,
	Z_PARTICLES,
	Z_FLASH,
	Z_CONTROLS,
};
