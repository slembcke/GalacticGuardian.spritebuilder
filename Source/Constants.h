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

#define DefaultsMusicKey @"MusicVolume"
#define DefaultsSoundKey @"SoundVolume"
#define DefaultsDifficultyHardKey @"DifficultyMode"


#define GameSceneSize 1024.0


static NSString * const ship_names[] =			{@"Retribution", @"Defiant", @"Freedom"};
static NSString * const ship_fileNames[] =	{@"ShipPink", @"ShipGreen", @"ShipBlue"};

typedef NS_ENUM(NSUInteger, ShipType){
	Ship_Retribution, Ship_Defiant, Ship_Herald
};

static const int SpaceBucksTilLevel1EasyMode = 40;
static const int SpaceBucksTilLevel1HardMode = 200;
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
	Z_LINK,
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
