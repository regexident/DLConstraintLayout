//
//  DLCLViewController.h
//  DLConstraintLayout
//
//  Created by Vincent Esche on 3/13/13.
//  Copyright (c) 2013 Vincent Esche. All rights reserved.
//

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

@interface DLCLViewController : UIViewController

@property (readwrite, strong, nonatomic) IBOutlet UIView *contentView;
@property (readwrite, strong, nonatomic) IBOutlet UISlider *slider;

#else

#import <Cocoa/Cocoa.h>

@interface DLCLViewController : NSViewController

@property (readwrite, strong, nonatomic) IBOutlet NSView *contentView;
@property (readwrite, strong, nonatomic) IBOutlet NSSlider *slider;

#endif

@property (readonly, strong, nonatomic) NSDictionary *layersByName;

@end
