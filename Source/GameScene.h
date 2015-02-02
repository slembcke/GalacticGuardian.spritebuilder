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


#import "Constants.h"

@class PlayerShip, EnemyShip, Bullet;


@interface GameScene : CCScene<CCPhysicsCollisionDelegate>

@property(nonatomic, readonly) CCNode *distortionNode;

@property(nonatomic, readonly) PlayerShip *playerShip;
@property(nonatomic, readonly) CGPoint playerPosition;

-(instancetype)initWithShipType:(ShipType) shipType;

-(void)splashDamageAt:(CGPoint)center radius:(float)radius damage:(int)damage;

-(void)drawFlash:(CGPoint) position withImage:(NSString*) imagePath;
-(void)drawBulletFlash:(Bullet *)fromBullet;

-(void)novaBombAt:(CGPoint)pos;

@end

// Recursive helper function to set up physics on the debris child nodes.
// It sets up collision properties, initial motion due to the explosion and the burn animation.
void InitDebris(CCNode *root, CCNode *node, CGPoint velocity, CCColor *burnColor);
