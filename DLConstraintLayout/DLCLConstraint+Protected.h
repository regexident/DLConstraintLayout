//
//  DLCLConstraint.h
//  DLConstraintLayout
//
//  Created by Vincent Esche on 3/14/13.
//  Copyright (c) 2013 Vincent Esche. All rights reserved.
//

#import "DLCLConstraint.h"

#ifndef DLConstraintLayout_DLCLConstraint_Protected_h
#define DLConstraintLayout_DLCLConstraint_Protected_h

typedef NS_ENUM(BOOL, DLCLConstraintAxis) {
	DLCLConstraintAxisX = 0,
	DLCLConstraintAxisY = 1
};

typedef NS_ENUM(NSUInteger, DLCLConstraintAxisAttribute) {
	DLCLConstraintAxisAttributeMin  = 0,
	DLCLConstraintAxisAttributeMid  = 1,
	DLCLConstraintAxisAttributeMax  = 2,
	DLCLConstraintAxisAttributeSize = 3
};

@interface DLCLConstraint ()

- (BOOL)isEqualToConstraint:(DLCLConstraint *)constraint;

+ (BOOL)getAxis:(DLCLConstraintAxis *)axis axisAttribute:(DLCLConstraintAxisAttribute *)axisAttribute fromAttribute:(DLCLConstraintAttribute)attribute;
- (BOOL)getAxis:(DLCLConstraintAxis *)axis axisAttribute:(DLCLConstraintAxisAttribute *)axisAttribute;
- (BOOL)getSourceAxis:(DLCLConstraintAxis *)axis axisAttribute:(DLCLConstraintAxisAttribute *)axisAttribute;

- (CALayer *)sourceLayerInSuperlayer:(CALayer *)superlayer;

@end

#endif