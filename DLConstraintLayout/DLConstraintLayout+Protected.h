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