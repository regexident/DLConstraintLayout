//
//  DLConstraintLayout.h
//  DLConstraintLayout
//
//  Created by Vincent Esche on 3/13/13.
//  Copyright (c) 2013 Vincent Esche. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CALayer+DLConstraintLayout.h"
#import "DLCLConstraint.h"
#import "DLCLConstraintLayoutManager.h"

#ifndef DLConstraintLayout_DLConstraintLayout_h
#define DLConstraintLayout_DLConstraintLayout_h

#if defined(DLCL_USE_NATIVE_CA_NAMESPACE) && TARGET_OS_IPHONE

@compatibility_alias CAConstraint DLCLConstraint;
@compatibility_alias CAConstraintLayoutManager DLCLConstraintLayoutManager;

typedef DLCLConstraintAttribute CAConstraintAttribute;

#define kCAConstraintMinX   kDLCLConstraintMinX
#define kCAConstraintMidX   kDLCLConstraintMidX
#define kCAConstraintMaxX   kDLCLConstraintMaxX
#define kCAConstraintWidth  kDLCLConstraintWidth
#define kCAConstraintMinY   kDLCLConstraintMinY
#define kCAConstraintMidY   kDLCLConstraintMidY
#define kCAConstraintMaxY   kDLCLConstraintMaxY
#define kCAConstraintHeight kDLCLConstraintHeight

#endif

#endif

@interface DLConstraintLayout : NSObject

@end

/*
 Important:
 You will most likely have to add the "-lc++" linker flag in the loader bundle to have it compile.
 Further more on iOS you will have to add the "-ObjC" linker flag in the loader bundle for categories to load properly.
// Static libraries require  for categories to load properly (on iOS at least)!

*/