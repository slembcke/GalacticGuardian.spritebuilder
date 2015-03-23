//////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2006 Audiokinetic Inc. / All Rights Reserved
//
//////////////////////////////////////////////////////////////////////

// AkSimd.h

/// \file 
/// AKSIMD - iPhone implementation



#ifndef _AKSIMD_PLATFORM_H_
#define _AKSIMD_PLATFORM_H_

#include <AK/SoundEngine/Common/AkTypes.h>

#undef AKSIMD_GETELEMENT_V4F32
#define AKSIMD_GETELEMENT_V4F32( __vName, __num__ )			((float*)&(__vName))[(__num__)]							///< Retrieve scalar element from vector.

#undef AKSIMD_GETELEMENT_V2F32
#define AKSIMD_GETELEMENT_V2F32( __vName, __num__ )			((float*)&(__vName))[(__num__)]							///< Retrieve scalar element from vector.

#undef AKSIMD_GETELEMENT_V4I32
#define AKSIMD_GETELEMENT_V4I32( __vName, __num__ )			((int*)&(__vName))[(__num__)]							///< Retrieve scalar element from vector.

#ifdef AK_CPU_ARM_NEON
#define AK_IOS_ARM_NEON
#include <AK/SoundEngine/Platforms/arm_neon/AkSimd.h>
#else
#include <AK/SoundEngine/Platforms/Generic/AkSimd.h>
#endif
#endif //_AKSIMD_PLATFORM_H_

