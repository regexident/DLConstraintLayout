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

typedef struct {
    DLCLConstraintAttribute attribute;
    DLCLConstraintAttribute source_attribute;
    __unsafe_unretained CALayer *source_layer;
    CGFloat scale;
    CGFloat offset;
} DLCLConstraintStruct;

#ifdef __cplusplus
extern "C" {
#endif
    
    DLCLConstraintStruct DLCLConstraintStructMake(DLCLConstraintAttribute attribute, DLCLConstraintAttribute source_attribute, CALayer *source_layer, CGFloat scale, CGFloat offset);
    
    DLCLConstraintAxis DLCLConstraintAttributeGetAxis(DLCLConstraintAttribute attribute);
    DLCLConstraintAxisAttribute DLCLConstraintAttributeGetAxisAttribute(DLCLConstraintAttribute attribute);
    
#ifdef __cplusplus
}
#endif

@interface DLCLConstraint ()

@property (readonly, assign, nonatomic) DLCLConstraintStruct constraintStruct;
@property (readonly, strong, nonatomic) CALayer *sourceLayer;

- (CALayer *)detectSourceLayerInSuperlayer:(CALayer *)superlayer;

- (BOOL)isEqualToConstraint:(DLCLConstraint *)constraint;

@end

#endif