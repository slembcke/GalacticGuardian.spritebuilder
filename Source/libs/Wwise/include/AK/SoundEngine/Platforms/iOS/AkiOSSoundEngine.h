//////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2006 Audiokinetic Inc. / All Rights Reserved
//
//////////////////////////////////////////////////////////////////////

// AkiOSSoundEngine.h

/// \file 
/// Main Sound Engine interface, specific iOS.

#ifndef _AK_IOS_SOUND_ENGINE_H_
#define _AK_IOS_SOUND_ENGINE_H_

#include <AK/SoundEngine/Common/AkTypes.h>
#include <AK/Tools/Common/AkPlatformFuncs.h>

#import <AudioToolbox/AudioToolbox.h>

namespace AK
{
	namespace SoundEngine
	{
		namespace iOS
		{
			/// IDs of iOS inter-app audio mixing (muting) policies, partially exposed from the audio backend CoreAudio's audio session categories. Refer to Xcode CoreAudio documentation for details on the audio session categories.
			///
			/// \remark Because some audio session categories always allow or forbid inter-app audio mixing, the audio session categories could incur conflicts in the mixing policies when combined with the bMuteOtherApps field. To avoid such conflicts, the policies determined by the audio session categories always override bMuteOtherApps when combined. The covered conflicts are:
			/// - AkPlatformInitSettings.eAudioSessionCategory is set to kAudioSessionCategory_AmbientSound, but AkPlatformInitSettings.bMuteOtherApps is set to true.
			/// - AkPlatformInitSettings.eAudioSessionCategory is set to one of the categories other than kAudioSessionCategory_AmbientSound, kAudioSessionCategory_PlayAndRecord, or kAudioSessionCategory_MediaPlayback, but AkPlatformInitSettings.bMuteOtherApps is set to false.
			///
			/// \sa
			/// - \ref AkPlatformInitSettings
			enum AudioSessionCategory
			{
				kAudioSessionCategory_AmbientSound               = 1634558569, // 'ambi'
				kAudioSessionCategory_SoloAmbientSound           = 1936682095, // 'solo'
				kAudioSessionCategory_PlayAndRecord              = 1886151026  // 'plar'
			};

			/// iOS-only callback function prototype used for audio input source plugin. Implement this function to transfer the input sample data to the sound engine and perform brief custom processing.
			/// \remark See the remarks of \ref AkGlobalCallbackFunc.
			///
			/// \sa
			/// - \ref AkPlatformInitSettings
			typedef AKRESULT ( * AudioInputCallbackFunc )(
				AudioBufferList* io_Data, ///< An exposed CoreAudio structure that holds the input audio samples generated from audio input hardware. The buffer is pre-allocated by the sound engine and the buffer size can be obtained from the structure. Refer to the microphone demo of the IntegrationDemo for an example of usage.
				void* in_pCookie ///< User-provided data, e.g., a user structure.
				);

			/// iOS-only callback function prototype used for handling audio session interruption. It is mandatory to implement this callback to respond to audio interruptions such as phone calls or alarms according to the application logic. The examples of such responses include calling relevant sound engine API to suspend the device or wake up the device from suspend, and enabling certain UI elements when an interruption happens.
			/// \remark 
			/// - Under interruptible audio session categories, the application may need to respond to audio interruptions such as phone calls, alarms, or the built-in music player control from various remote control interfaces, according to its own policy. Such a policy may include pausing and resuming the sound engine pipeline, pausing and resuming the entire game, and updating UI elements either as the feedback to users about the interruption status, or as a means for the users to restore the audio manually if the application requires the user intervention. 
			/// - It is mandatory to implement this user callback function. The sound engine must be paused or resumed by calling AK::SoundEngine::Suspend() and AK::SoundEngine::WakeupFromSuspend() explicitly in this callback. It is up to the user to perform other policies such as pausing the entire game when entering the interruption and resuming the game when leaving the interruption. This is useful for games in which audio is essential to the gameplay.
			/// - Failure to implement this callback will leave the sound engine in a broken state when interruptions occur.
			/// - It was reported that on certain iOS devices (e.g. iOS 6.1) the audio pipeline may occasionally fail to resume after the interruption is over. In this rare case, the application can retry calling this API function in \ref AudioInterruptionCallbackFunc, but also ensure by setting up an application logic that no infinite loop could happen. This usually fixes the issue.
			/// - The callback is thread safe.
			///
			/// \sa
			/// - \ref ListenToAudioSessionInterruption
			/// - \ref AkGlobalCallbackFunc
			/// - \ref AkPlatformInitSettings
			typedef AKRESULT ( * AudioInterruptionCallbackFunc )(
				bool in_bEnterInterruption,	///< Indicating whether or not an interruption is about to start (e.g., an incoming call is received) or end (e.g., the incoming call is dismissed).

				void* in_pCookie ///< User-provided data, e.g., a user structure.
				);

		}
	}
}

/// Platform specific initialization settings
/// \sa AK::SoundEngine::Init
/// \sa AK::SoundEngine::GetDefaultPlatformInitSettings
/// - \ref soundengine_initialization_advanced_soundengine_using_memory_threshold
/// - \ref AK::SoundEngine::iOS::AudioSessionCategory

struct AkPlatformInitSettings
{
	// Threading model.
    AkThreadProperties  threadLEngine;			///< Lower engine threading properties
	AkThreadProperties  threadBankManager;		///< Bank manager threading properties (its default priority is AK_THREAD_PRIORITY_NORMAL)
	AkThreadProperties  threadMonitor;			///< Monitor threading properties (its default priority is AK_THREAD_PRIORITY_ABOVENORMAL). This parameter is not used in Release build.
	
    // Memory.
	AkReal32            fLEngineDefaultPoolRatioThreshold;	///< 0.0f to 1.0f value: The percentage of occupied memory where the sound engine should enter in Low memory mode. \ref soundengine_initialization_advanced_soundengine_using_memory_threshold
	AkUInt32            uLEngineDefaultPoolSize;///< Lower Engine default memory pool size
	AkUInt32			uSampleRate;			///< Sampling Rate. Default 48000 Hz
	// Voices.
	AkUInt16            uNumRefillsInVoice;		///< Number of refill buffers in voice buffer. 2 == double-buffered, defaults to 4.
	AK::SoundEngine::iOS::AudioSessionCategory eAudioSessionCategory;	///< Audio session mode defined by CoreAudio. Only three modes are supported in current release. Certain category, e.g., kAudioSessionCategory_AmbientSound, cannot be used if bMuteOtherApps is set to true.
	bool				bMuteOtherApps;			///< Mute other audio-enabled applications in the background when set to true. If set to false, hardware sampling rate is not guaranteed (resampling might happen, limitation of iOS). Ignored when a conflicting audio session category is used. If set to true, the application needs to handle remote control events to block all other audio apps from hijacking the shared audio session (See the app delegate of the IntegrationDemo for an example). Set to true by default.
	AK::SoundEngine::iOS::AudioInputCallbackFunc inputCallback; ///< Application-defined audio input callback function.
	void* inputCallbackCookie; ///< Application-defined user data for the audio input callback function.
	AK::SoundEngine::iOS::AudioInterruptionCallbackFunc interruptionCallback; ///< Application-defined audio interruption callback function.
	void* interruptionCallbackCookie; ///< Application-defined user data for the audio interruption callback function.
};

///< API used for audio output
///< Use with AkInitSettings to select the API used for audio output.
///< \sa AK::SoundEngine::Init
enum AkAudioAPI
{
	AkAPI_Default = 1 << 0,		///< Default audio subsystem
	AkAPI_Dummy = 1 << 2,		///< Dummy output, simply eats the audio stream and outputs nothing.
};

///< Used with \ref AK::SoundEngine::AddSecondaryOutput to specify the type of secondary output.
enum AkAudioOutputType
{
	AkOutput_Dummy = 1 << 2,		///< Dummy output, simply eats the audio stream and outputs nothing.
	AkOutput_MergeToMain = 1 << 3,	///< This output will mix back its content to the main output, after the master mix.
	AkOutput_Main = 1 << 4,			///< Main output.  This cannot be used with AddSecondaryOutput, but can be used to query information about the main output (GetSpeakerConfiguration for example).	
	AkOutput_NumOutputs = 1 << 5,	///< Do not use.
};

namespace AK
{
	namespace SoundEngine
	{
		namespace iOS
		{
			/// Handle audio interruptions on iOS devices by calling the sound engine's internal interruption handler function from the application. A user-registered callback \ref AudioInterruptionCallbackFunc is called to perform application-specific tasks, including pausing and resuming the the sound engine for the incoming interruption such as phone calls, alarms, or music app activities from remote control;
			/// Call this function with \ref in_bEnterInterruption set to true if the call is made when the audio interruption begins, and with \ref in_bEnterInterruption set to false if the call is made when the interruption ends.
			/// If \ref in_bRunUserCallback is set to true, user callback will be called, otherwise skipped. See Remark for details.
			///
			/// \return
			/// - Ak_Suceess: Pausing upon interruption or resuming upon recovery was successful.
			/// - Ak_Fail: Pausing upon interruption or resuming upon recovery failed.
			/// - Ak_Cancel: The retry operation was cancelled because the previous operation has succeeded or the sound engine is uninitialized.
			///
			/// \remark
			/// - When an audio interruption comes from phone calls and alarms, the sound engine's internal interruption handler is triggered automatically, both when the interruption begins and ends. However, by the iOS design, when the interruption comes from the music remote control, only the beginning of the interruption is triggered; the end of the interruption needs to be handled by the application. It is thus necessary to design a user interaction to handle the end of the interruption. Call this API in the application's UI delegate to restore the application's audio after the audio interruption ends, with \ref in_bEnterInterruption set to false. The UI delegate can be triggered in \ref AudioInterruptionCallbackFunc.
			/// - When the audio interruption is successfully ended by calling this API, the application's audio will be restored and the interruption source will be silenced if the source application is still active.
			/// - The user callback, if registered, is always called when this API is called.
			/// - Avoid calling this API inside the user interruption callback \ref AudioInterruptionCallbackFunc in order to void infinite loops.
			/// - It was reported that on certain iOS devices (e.g. iOS 6.1) the audio pipeline may occasionally fail to resume after the interruption is over. In this rare case, the application can retry calling this API function in \ref AudioInterruptionCallbackFunc, but also ensure by setting up an application logic that no infinite loop could happen. This usually fixes the issue.
			/// - Refer to \ref soundengine_integration_samplecode for an example of handling audio session interruptions.
			///
			/// \sa
			/// - \ref AudioInterruptionCallbackFunc
			/// - \ref AkPlatformInitSettings
			///
			AK_EXTERNAPIFUNC( AKRESULT, ListenToAudioSessionInterruption )(
				bool in_bEnterInterruption	///< Flag indicating whether or not an interruption is about to start (e.g., an incoming call is received) or end (e.g., the incoming call is dismissed).
				);
		}
	}
}

#endif //_AK_IOS_SOUND_ENGINE_H_
