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

@property (readonly, assign, nonatomic) DLCLConstraintAttribute attribute;
@property (readonly, assign, nonatomic) CGFloat offset;
@property (readonly, assign, nonatomic) CGFloat scale;
@property (readonly, assign, nonatomic) DLCLConstraintAttribute sourceAttribute;
@property (readonly, copy, nonatomic) NSString *sourceName;

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