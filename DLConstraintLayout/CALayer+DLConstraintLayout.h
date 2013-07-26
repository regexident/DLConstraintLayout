//
//  CALayer+DLConstraintLayout.h
//  DLConstraintLayout
//
//  Created by Vincent Esche on 3/13/13.
//  Copyright (c) 2013 Vincent Esche. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "DLConstraintLayout.h"

@class DLCLConstraint;

@protocol CALayer_DLConstraintLayout <NSObject>

@optional

- (id)layoutManager;
- (void)setLayoutManager:(id)layoutManager;

- (NSArray *)constraints;
- (void)setConstraints:(NSArray *)constraints;

- (void)addConstraint:(DLCLConstraint *)constraint;

@end

@interface CALayer (DLConstraintLayout) <CALayer_DLConstraintLayout>

// the methods declared in protocol CALayer_DLCLConstraintLayout get added in category's load method

@end
