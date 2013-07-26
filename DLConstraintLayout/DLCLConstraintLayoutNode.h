//
//  DLCLConstraintLayoutNode.h
//  DLConstraintLayout
//
//  Created by vesche on 4/9/13.
//  Copyright (c) 2013 Regexident. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "DLCLConstraint+Protected.h"

@interface DLCLConstraintLayoutNode : NSObject

@property (readonly, unsafe_unretained, nonatomic) CALayer *layer;
@property (readonly, assign, nonatomic) DLCLConstraintAxis axis;
@property (readonly, strong, nonatomic) NSSet *constraints;
@property (readonly, strong, nonatomic) NSSet *incoming;
@property (readonly, strong, nonatomic) NSSet *outgoing;

- (id)initWithAxis:(DLCLConstraintAxis)axis forLayer:(CALayer *)layer;
+ (id)nodeWithAxis:(DLCLConstraintAxis)axis forLayer:(CALayer *)layer;

- (void)addConstraint:(DLCLConstraint *)constraint;

- (BOOL)hasDependencyTo:(DLCLConstraintLayoutNode *)node;
- (void)addDependencyTo:(DLCLConstraintLayoutNode *)node;
- (void)removeDependencyTo:(DLCLConstraintLayoutNode *)node;

@end
