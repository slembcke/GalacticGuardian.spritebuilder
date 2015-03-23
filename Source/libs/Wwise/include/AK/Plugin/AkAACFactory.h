//////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2010 Audiokinetic Inc. / All Rights Reserved
//
//////////////////////////////////////////////////////////////////////

// AkAACFactory.h

/// \file
/// Codec plug-in unique ID and creation functions (hooks) necessary to register the AAC codec in the sound engine.

#ifndef _AK_AACFACTORY_H_
#define _AK_AACFACTORY_H_

#ifdef AKSOUNDENGINE_DLL

// AAC Decoder
#ifdef AKAACDECODER_EXPORTS
	#define AKAACDECODER_API __declspec(dllexport) ///< AAC decoder API exportation definition
#else
	#define AKAACDECODER_API __declspec(dllimport) ///< AAC decoder API exportation definition
#endif // Export

#else

#define AKAACDECODER_API

#endif // AKSOUNDENGINE_DLL

class IAkSoftwareCodec;
/// Prototype of the AAC codec bank source creation function.
AKAACDECODER_API IAkSoftwareCodec* CreateAACBankPlugin( 
	void* in_pCtx			///< Bank source decoder context
	);

/// Prototype of the AAC codec file source creation function.
AKAACDECODER_API IAkSoftwareCodec* CreateAACFilePlugin( 
	void* in_pCtx 			///< File source decoder context
	);

#endif // _AK_AACFACTORY_H_
