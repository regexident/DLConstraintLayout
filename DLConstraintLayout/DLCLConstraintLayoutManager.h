//
//  DLCLConstraintLayoutManager.h
//  DLConstraintLayout
//
//  Created by Vincent Esche on 3/14/13.
//  Copyright (c) 2013 Vincent Esche. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@protocol DLCLConstraintLayoutManager <NSObject>

+ (instancetype)layoutManager;

- (void)invalidateLayoutOfLayer:(CALayer *)layer;
- (void)layoutSublayersOfLayer:(CALayer *)layer;
- (CGSize)preferredSizeOfLayer:(CALayer *)layer;

@end

@interface DLCLConstraintLayoutManager : NSObject <DLCLConstraintLayoutManager>

// Looks weird, but just consider all methods in the same named protocol to be listed in here.
// Having them in a protocol makes it easier to dynamically check API compatibility via objc runtime.

@end
