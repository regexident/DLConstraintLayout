//
//  DLCLConstraintLayoutSolver.h
//  DLConstraintLayout
//
//  Created by vesche on 4/9/13.
//  Copyright (c) 2013 Regexident. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CALayer;

@interface DLCLConstraintLayoutSolver : NSObject

@property (readonly, unsafe_unretained, nonatomic) CALayer *layer;

- (id)initWithLayer:(CALayer *)layer;
+ (instancetype)solverWithLayer:(CALayer *)layer;

- (void)solveLayout;

@end
