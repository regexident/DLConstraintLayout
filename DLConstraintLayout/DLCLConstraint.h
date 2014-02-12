//
//  DLCLConstraint.h
//  DLConstraintLayout
//
//  Created by Vincent Esche on 3/14/13.
//  Copyright (c) 2013 Vincent Esche. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#ifndef DLConstraintLayout_DLCLConstraint_h
#define DLConstraintLayout_DLCLConstraint_h

typedef enum : int {
	kDLCLConstraintMinX,
	kDLCLConstraintMidX,
	kDLCLConstraintMaxX,
	kDLCLConstraintWidth,
	kDLCLConstraintMinY,
	kDLCLConstraintMidY,
	kDLCLConstraintMaxY,
	kDLCLConstraintHeight,
} DLCLConstraintAttribute;

@protocol DLCLConstraint <NSObject>

// These must match those from CAConstraint:
// https://developer.apple.com/library/mac/DOCUMENTATION/GraphicsImaging/Reference/CAConstraint_class/Introduction/Introduction.html
@property (readonly) DLCLConstraintAttribute attribute;
@property (readonly) CGFloat offset;
@property (readonly) CGFloat scale;
@property (readonly) DLCLConstraintAttribute sourceAttribute;
@property (readonly) NSString *sourceName;

+ (instancetype)constraintWithAttribute:(DLCLConstraintAttribute)attr relativeTo:(NSString *)srcLayer attribute:(DLCLConstraintAttribute)srcAttr scale:(CGFloat)scale offset:(CGFloat)offset;
+ (instancetype)constraintWithAttribute:(DLCLConstraintAttribute)attr relativeTo:(NSString *)srcLayer attribute:(DLCLConstraintAttribute)srcAttr offset:(CGFloat)offset;
+ (instancetype)constraintWithAttribute:(DLCLConstraintAttribute)attr relativeTo:(NSString *)srcLayer attribute:(DLCLConstraintAttribute)srcAttr;
- (id)initWithAttribute:(DLCLConstraintAttribute)attr relativeTo:(NSString *)srcLayer attribute:(DLCLConstraintAttribute)srcAttr scale:(CGFloat)scale offset:(CGFloat)offset;

@end

@interface DLCLConstraint : NSObject <DLCLConstraint>

// Looks weird, but just consider all methods in the same named protocol to be listed in here.
// Having them in a protocol makes it easier to dynamically check API compatibility via objc runtime.

@end

#endif