//////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2006 Audiokinetic Inc. / All Rights Reserved
//
//////////////////////////////////////////////////////////////////////
// AkAudioInputSourceFactory.h

/// \file 
///! Plug-in unique ID and creation functions (hooks) necessary to register the audio input plug-in to the sound engine.
/// <br><b>Wwise source name:</b>  AudioInput
/// <br><b>Library file:</b> AkAudioInputSource.lib

#ifndef _AK_AUDIOINPUTSOURCEFACTORY_H_
#define _AK_AUDIOINPUTSOURCEFACTORY_H_

#include <AK/SoundEngine/Common/IAkPlugin.h>

// Declarations for semi-private sound engine methods
namespace AK
{
    namespace SoundEngine
    {
        AK_FUNC( AkPlayingID, PlaySourcePlugin )( AkUInt32 in_plugInID, AkUInt32 in_CompanyID, AkGameObjectID in_GameObjID );
        AK_FUNC( AKRESULT, StopSourcePlugin )( AkUInt32 in_plugInID, AkUInt32 in_CompanyID, AkPlayingID in_playingID );
    }
}

///
/// - This is the plug-in's unique ID (combined with the AKCOMPANYID_AUDIOKINETIC company ID)
/// - This ID must be the same as the plug-in ID in the plug-in's XML definition file, and is persisted in project files. 
/// \akwarning
/// Changing this ID will cause existing projects not to recognize the plug-in anymore.
/// \endakwarning
const AkUInt32 AKSOURCEID_AUDIOINPUT = 200;

/// Static creation function that returns an instance of the sound engine plug-in parameter node to be hooked by the sound engine plug-in manager.
AK_EXTERNAPIFUNC( AK::IAkPluginParam *, CreateAudioInputSourceParams )(
	AK::IAkPluginMemAlloc * in_pAllocator			///< Memory allocator interface
	);

/// Plugin mechanism. Source create function and register its address to the plug-in manager.
AK_EXTERNAPIFUNC( AK::IAkPlugin*, CreateAudioInputSource )(
	AK::IAkPluginMemAlloc * in_pAllocator			///< Memory allocator interface
	);

////////////////////////////////////////////////////////////////////////////////////////////
// API external to the plug-in, to be used by the game.

/// Callback requesting for the AkAudioFormat to use for the plug-in instance.
/// Refer to the Source Input plugin documentation to learn more about the valid formats.
/// \sa \ref soundengine_plugins_source
AK_CALLBACK( void, AkAudioInputPluginGetFormatCallbackFunc )(
    AkPlayingID		in_playingID,   ///< Playing ID (same that was returned from the PostEvent call or from the PlayAudioInput call.
    AkAudioFormat&  io_AudioFormat  ///< Already filled format, modify it if required.
    );

/// Function that returns the Gain to be applied to the Input Plugin.
/// [0..1] range where 1 is maximum volume.
AK_CALLBACK( AkReal32, AkAudioInputPluginGetGainCallbackFunc )(
    AkPlayingID		in_playingID    ///< Playing ID (same that was returned from the PostEvent call or from the PlayAudioInput call.
    );

/// \typedef void( *AkAudioInputPluginExecuteCallbackFunc )( AkPlayingID in_playingID, AkAudioBuffer* io_pBufferOut )
/// Callback requesting for new data for playback.
/// \param in_playingID Playing ID (same that was returned from the PostEvent call or from the PlayAudioInput call
/// \param io_pBufferOut Buffer to fill
/// \remarks See IntegrationDemo sample for a sample on how to implement it.
AK_CALLBACK( void, AkAudioInputPluginExecuteCallbackFunc )(
    AkPlayingID		in_playingID,
    AkAudioBuffer*	io_pBufferOut
    );

/// Starts the playback of the AudioInputPlugin plugin on the specified game object.
/// If you have multiple instances of the AudioInput plugin, you must keep track of the PlayingIDs
/// since they will be required on the callbacks.
/// If the plugin is infinitely playing, you must keep track of the playing ID to stop it using StopAudioInput().
/// WARNING: This function was added to allow the playback of a plug-in without having
/// an event, not even an init bank being loaded. But this system will also bypass most of the project
/// hierarchy.
/// The usual way for playing AudioInput plug-in is by creating an event in Wwise project, allowing
/// you to have full control on all parameters.
/// \sa StopAudioInput
AkForceInline AKRESULT PlayAudioInput(
    AkPlayingID& out_PlayingID, ///< Playing ID that will be returned on callbacks
    AkGameObjectID in_GameObjID ///< Game object to play the sound on.
    )
{
	out_PlayingID = AK::SoundEngine::PlaySourcePlugin( AKSOURCEID_AUDIOINPUT, AKCOMPANYID_AUDIOKINETIC, in_GameObjID );
    return out_PlayingID == AK_INVALID_PLAYING_ID ? AK_Fail : AK_Success;
}

/// This will only stop instances that were started using PlayAudioInput.
/// \sa PlayAudioInput
AkForceInline AKRESULT StopAudioInput(
    AkPlayingID in_PlayingID    ///< Playing ID of the Audio Input to be stopped.
    )
{
    return AK::SoundEngine::StopSourcePlugin( AKSOURCEID_AUDIOINPUT, AKCOMPANYID_AUDIOKINETIC, in_PlayingID );
}

/// This function should be called at the same place the AudioInput plug-in is being registered.
AK_EXTERNAPIFUNC( void, SetAudioInputCallbacks )(
                AkAudioInputPluginExecuteCallbackFunc in_pfnExecCallback, 
                AkAudioInputPluginGetFormatCallbackFunc in_pfnGetFormatCallback = NULL, // Optional
                AkAudioInputPluginGetGainCallbackFunc in_pfnGetGainCallback = NULL      // Optional
                );
////////////////////////////////////////////////////////////////////////////////////////////

/*
Use the following code to register your plug-in

AK::SoundEngine::RegisterPlugin( AkPluginTypeSource, 
								 AKCOMPANYID_AUDIOKINETIC, 
								 AKSOURCEID_AUDIOINPUT,
								 CreateAudioInputSource,
								 CreateAudioInputSourceParams );
*/

#endif // _AK_AUDIOINPUTSOURCEFACTORY_H_
