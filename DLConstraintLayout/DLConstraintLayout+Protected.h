//
//  DLConstraintLayout+Protected.h
//  DLConstraintLayout
//
//  Created by Vincent Esche on 3/13/13.
//  Copyright (c) 2013 Vincent Esche. All rights reserved.
//

#import "DLConstraintLayout.h"

#ifndef DLConstraintLayout_DLConstraintLayout_Protected_h
#define DLConstraintLayout_DLConstraintLayout_Protected_h

#if __has_feature(objc_arc)

#define DLCL_RETAIN(_o) (_o)
#define DLCL_RELEASE(_o)
#define DLCL_AUTORELEASE(_o) (_o)

#else

#define DLCL_RETAIN(_o) [(_o) retain]
#define DLCL_RELEASE(_o) [(_o) release]
#define DLCL_AUTORELEASE(_o) [(_o) autorelease]

#endif

extern NSString * const kDLCAConstraintClassName;
extern NSString * const kDLCAConstraintLayoutManagerClassName;

#ifdef __cplusplus
extern "C" {
#endif
	
BOOL DLCLClassImplementsProtocol(Class aClass, Protocol *aProtocol);

#ifdef __cplusplus
}
#endif

#endif