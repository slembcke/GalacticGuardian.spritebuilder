//////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2006 Audiokinetic Inc. / All Rights Reserved
//
//////////////////////////////////////////////////////////////////////

#ifndef _AK_AKASSERT_H_
#define _AK_AKASSERT_H_

#if ! defined( AKASSERT )

	#include <AK/SoundEngine/Common/AkTypes.h> //For AK_Fail/Success
	#include <assert.h>
	#include <AK/SoundEngine/Common/AkSoundEngineExport.h>

	#if defined( _DEBUG )

		#if defined( __SPU__ )

			// Note: No assert hook on SPU
			#include "spu_printf.h"
			#include "libsn_spu.h"
			#define AKASSERT(Condition)																\
				if ( !(Condition) )																	\
				{																					\
					spu_printf( "Assertion triggered in file %s at line %d\n", __FILE__, __LINE__ );\
					/*snPause();*/																	\
				}																	

		#else // defined( __SPU__ )

			#ifndef AK_ASSERT_HOOK
				AK_CALLBACK( void, AkAssertHook)( 
										const char * in_pszExpression,	///< Expression
										const char * in_pszFileName,	///< File Name
										int in_lineNumber				///< Line Number
										);
				#define AK_ASSERT_HOOK
			#endif

			extern AKSOUNDENGINE_API AkAssertHook g_pAssertHook;

			#if defined( AK_WII_FAMILY )

					inline void _AkAssertHook(
									bool bcondition,
									const char * in_pszExpression,
									const char * in_pszFileName,
									int in_lineNumber
									)
					{
						if( !bcondition )
							g_pAssertHook( in_pszExpression, in_pszFileName, in_lineNumber);
					}

					#define AKASSERT(Condition) if ( g_pAssertHook )   \
													_AkAssertHook((bool)(Condition), #Condition, __FILE__, __LINE__); \
												else                                \
												{ \
													if (!(bool)(Condition)) \
													{ \
														OSHalt(#Condition); \
													} \
												}
			#elif defined( AK_APPLE )
					#include <TargetConditionals.h>
					#define CallDebugger pthread_kill (pthread_self(), SIGTRAP);

					inline void _MacAssert( const char * in_pFunc , const char * in_pFile , unsigned in_LineNum, const char * in_pCondition )
					{
						printf ("%s:%u:%s failed assertion `%s'\n", in_pFile, in_LineNum, in_pFunc, in_pCondition);
						CallDebugger
					}

					#define _AkAssertHook(_Expression) ( (_Expression) || (g_pAssertHook( #_Expression, __FILE__, __LINE__), 0) )

					#define AKASSERT(Condition) if ( g_pAssertHook )   \
												_AkAssertHook(Condition);          \
					else                                \
												(__builtin_expect(!(Condition), 0) ? _MacAssert(__func__, __FILE__, __LINE__, #Condition) : (void)0)	

			#elif defined( AK_VITA )
				
				#define _AkAssertHook(_Expression) ( (_Expression) || (g_pAssertHook( #_Expression, __FILE__, __LINE__), 0) )

				#define AKASSERT(Condition)			\
					_Pragma( "diag_push" )			\
					_Pragma( "diag_suppress=237" )	\
					_Pragma( "diag_suppress=112" )	\
					if ( g_pAssertHook )			\
						_AkAssertHook(Condition);	\
					else							\
						assert(Condition);			\
					_Pragma( "diag_pop" )

			#elif defined( AK_ANDROID )
				#include <android/log.h>
				inline void _AndroidAssert( const char * in_pFunc , const char * in_pFile , unsigned in_LineNum, const char * in_pCondition )
				{
					__android_log_print(ANDROID_LOG_INFO, "AKASSERT","%s:%u:%s failed assertion `%s'\n", in_pFile, in_LineNum, in_pFunc, in_pCondition);
				}
				
				#define _AkAssertHook(_Expression) ( (_Expression) || (g_pAssertHook( #_Expression, __FILE__, __LINE__), 0) )


				#define AKASSERT(Condition) if ( g_pAssertHook )   \
												_AkAssertHook(Condition);          \
											else \
												(__builtin_expect(!(Condition), 0) ? _AndroidAssert(__func__, __FILE__, __LINE__, #Condition) : (void)0)
			#else
				
				#define _AkAssertHook(_Expression) ( (_Expression) || (g_pAssertHook( #_Expression, __FILE__, __LINE__), 0) )

				#define AKASSERT(Condition) if ( g_pAssertHook )   \
												_AkAssertHook(Condition);          \
											else                                \
												assert(Condition)

			#endif // defined( AK_WII )

		#endif // defined( __SPU__ )

		#define AKVERIFY AKASSERT

	#else // defined( _DEBUG )

		#define AKASSERT(Condition) ((void)0)
		#define AKVERIFY(x) ((void)(x))

	#endif // defined( _DEBUG )

	#define AKASSERT_RANGE(Value, Min, Max) (AKASSERT(((Value) >= (Min)) && ((Value) <= (Max))))

	#define AKASSERTANDRETURN( __Expression, __ErrorCode )\
		if (!(__Expression))\
		{\
			AKASSERT(__Expression);\
			return __ErrorCode;\
		}\

	#define AKASSERTPOINTERORFAIL( __Pointer ) AKASSERTANDRETURN( __Pointer != NULL, AK_Fail )
	#define AKASSERTSUCCESSORRETURN( __akr ) AKASSERTANDRETURN( __akr == AK_Success, __akr )

	#define AKASSERTPOINTERORRETURN( __Pointer ) \
		if ((__Pointer) == NULL)\
		{\
			AKASSERT((__Pointer) == NULL);\
			return ;\
		}\

	#if defined( AK_WIN ) && ( _MSC_VER >= 1600 )
		// Compile-time assert
		#define AKSTATICASSERT( __expr__, __msg__ ) static_assert( (__expr__), (__msg__) )
	#else
		// Compile-time assert
		#define AKSTATICASSERT( __expr__, __msg__ ) typedef char __AKSTATICASSERT__[(__expr__)?1:-1]
	#endif

#endif // ! defined( AKASSERT )

#endif //_AK_AKASSERT_H_

