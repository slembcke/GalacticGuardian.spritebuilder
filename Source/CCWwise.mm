/*
 * Cocos2D-SpriteBuilder: http://cocos2d.spritebuilder.com
 *
 * Copyright (c) 2015 Andy Korth or Cocos2D Authors
 *
 */

#import <Cocoa/Cocoa.h>
#import "CCWwise.h"

// C++ stuff
#include <cmath>
#include <cstdio>
#include <cassert>

// I thin wwise needs these
#include <AvailabilityMacros.h>
#include <AudioToolbox/AudioToolbox.h>

#include <CoreAudio/CoreAudioTypes.h>
#include <AK/SoundEngine/Common/AkTypes.h>
#include <AK/Tools/Common/AkPlatformFuncs.h>

//Need to provide sensible defaults.
namespace AK
{
    void * AllocHook( size_t in_size )
    {
        return malloc( in_size );
    }
    void FreeHook( void * in_ptr )
    {
        free( in_ptr );
    }
}

// Gotta add more stuff to config the init.
#include <AK/SoundEngine/Common/AkMemoryMgr.h>		// Memory Manager
#include <AK/SoundEngine/Common/AkModule.h>			// Default memory and stream managers

#include <AK/SoundEngine/Common/IAkStreamMgr.h>		// Streaming Manager
#include <AK/SoundEngine/Common/AkSoundEngine.h>    // Sound engine
#include <AK/MusicEngine/Common/AkMusicEngine.h>	// Music Engine
#include <AK/SoundEngine/Common/AkStreamMgrModule.h>	// AkStreamMgrModule
#include <AK/Comm/AkCommunication.h>

// This is the only thing I need out of cocos2d, for the Wwise game object.
#import "CCNode.h"

// needed for CAkFilePackageLowLevelIOBlocking definition.
#include "AkDefaultIOHookBlocking.h"
#include "AkFilePackageLowLevelIOBlocking.h"

@implementation CCWwise {
    /// We're using the default Low-Level I/O implementation that's part
    /// of the SDK's sample code, with the file package extension
    CAkFilePackageLowLevelIOBlocking* m_pLowLevelIO;
}

static CCWwise *shared;

+(instancetype)alloc
{
    NSAssert(shared == nil, @"Attempted to allocate a second instance of a singleton.");
    return [super alloc];
}

#define DEFAULT_POOL_SIZE 2*1024*1024
#define LENGINE_DEFAULT_POOL_SIZE 1*1024*1024

+ (CCWwise *) sharedManager{
    if (!shared){
        shared = [[self alloc] init];
        
        shared->m_pLowLevelIO = new CAkFilePackageLowLevelIOBlocking();
        
        AkMemSettings memSettings;
        AkStreamMgrSettings stmSettings;
        AkDeviceSettings deviceSettings;
        AkInitSettings initSettings;
        AkPlatformInitSettings platformInitSettings;
        AkMusicSettings musicInit;
        
        memSettings.uMaxNumPools = 20;
        AK::StreamMgr::GetDefaultSettings( stmSettings );
        AK::StreamMgr::GetDefaultDeviceSettings( deviceSettings );
        AK::SoundEngine::GetDefaultInitSettings( initSettings );
        
        initSettings.uDefaultPoolSize = DEFAULT_POOL_SIZE;

        AK::SoundEngine::GetDefaultPlatformInitSettings( platformInitSettings );
        platformInitSettings.uLEngineDefaultPoolSize = LENGINE_DEFAULT_POOL_SIZE;
        
        AK::MusicEngine::GetDefaultInitSettings( musicInit );
        
        UInt32 g_uSamplesPerFrame = initSettings.uNumSamplesPerFrame;
        
        AKRESULT res = AK::MemoryMgr::Init( &memSettings );
        if ( res != AK_Success )
        {
            NSLog(@"AK::MemoryMgr::Init() returned AKRESULT %d", res );
            abort();
        }
        
        // this isn't optional
        if ( !AK::StreamMgr::Create( stmSettings ) )
        {
            NSLog(@"AK::StreamMgr::Create() failed" );
            abort();
        }
        
        // this is for resolving files or something
        res = shared->m_pLowLevelIO->Init( deviceSettings );
        if ( res != AK_Success )
        {
            NSLog(@"m_lowLevelIO.Init() returned AKRESULT %d", res );
            abort();
        }

        // This is where the magic happens. Really it should be the only one call needed
        res = AK::SoundEngine::Init( &initSettings, &platformInitSettings );
        if ( res != AK_Success )
        {
            NSLog(@"AK::SoundEngine::Init() returned AKRESULT %d", res );
            abort();
        }
        
        res = AK::MusicEngine::Init( &musicInit );
        if ( res != AK_Success )
        {
            NSLog(@"Could not initialize the Music Engine returned AKRESULT %d", res );
            abort();
        }
        
        NSString *path = [[NSBundle mainBundle].resourcePath stringByAppendingString:@"/"];
        NSLog(@"WWise configured with base path: %@", path);
        shared->m_pLowLevelIO->SetBasePath(path.UTF8String);
        
        // Set global language. Low-level I/O devices can use this string to find language-specific assets.
        // even though I don't care
        if ( AK::StreamMgr::SetCurrentLanguage( AKTEXT( "English(US)" ) ) != AK_Success )
        {
            NSLog(@"couldn't set language but I don't care" );
        }
        
        AkCommSettings commSettings;
        AK::Comm::GetDefaultInitSettings( commSettings );
        res = AK::Comm::Init( commSettings );
        if ( res != AK_Success )
        {
            NSLog(@"Could not initialize communication: returned AKRESULT %d", res );
            abort();
        }
        
        NSLog(@"Successfully started wwise.");
    }
    
    return shared;
}

- (void) terminate
{
    NSLog(@"terminating sound engine.");
    
    AK::MusicEngine::Term();
    AK::SoundEngine::Term();
    
    // CAkFilePackageLowLevelIOBlocking::Term() destroys its associated streaming device
    // that lives in the Stream Manager, and unregisters itself as the File Location Resolver.
    m_pLowLevelIO->Term();
    
    if ( AK::IAkStreamMgr::Get() )
        AK::IAkStreamMgr::Get()->Destroy();
    
    // Terminate the Memory Manager
    AK::MemoryMgr::Term();
}

// My code here:
- (void) RenderAudio
{
    AK::SoundEngine::RenderAudio();
}

- (void) registerGameObject:(CCNode *) n
{
     AK::SoundEngine::RegisterGameObj( (AkGameObjectID) n, [n.name UTF8String] );
}

- (void) postEvent:(NSString *) eventName forGameObject:(CCNode *) n
{
    AK::SoundEngine::PostEvent( [eventName UTF8String], (AkGameObjectID) n );
}

- (BOOL) loadBank:(NSString *)soundBankFile
{
    AkBankID bankID;
    if ( AK::SoundEngine::LoadBank( [soundBankFile UTF8String], AK_DEFAULT_POOL_ID, bankID ) != AK_Success )
    {
        CCLOG(@"Failed loading sound bank %@", soundBankFile);
        return false;
    }
    return true;
}

@end
