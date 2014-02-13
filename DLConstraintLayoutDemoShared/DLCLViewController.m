//
//  DLCLViewController.m
//  DLConstraintLayout
//
//  Created by Vincent Esche on 3/13/13.
//  Copyright (c) 2013 Vincent Esche. All rights reserved.
//

#import "DLCLViewController.h"

#if TARGET_OS_IPHONE

#import <DLConstraintLayout/DLConstraintLayout.h>

#else

#import "DLConstraintLayout.h"
#import <QuartzCore/QuartzCore.h>

#endif

NSString * const kSuperName = @"superlayer";
NSString * const kCenterName = @"center";
NSString * const kTopName = @"top";
NSString * const kBottomName = @"bottom";
NSString * const kLeftName = @"left";
NSString * const kRightName = @"right";
NSString * const kTopLeftName = @"topLeft";
NSString * const kTopRightName = @"topRight";
NSString * const kBottomLeftName = @"bottomLeft";
NSString * const kBottomRightName = @"bottomRight";

void DLCLConstrainLayer(CALayer *layer, CAConstraintAttribute attr, NSString *source, CAConstraintAttribute sourceAttr) {
	[layer addConstraint:[CAConstraint constraintWithAttribute:attr relativeTo:source attribute:sourceAttr]];
}

@interface DLCLViewController ()

@property (readwrite, strong, nonatomic) NSDictionary *layersByName;

@end

@implementation DLCLViewController

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
	self = [super initWithNibName:nibName bundle:nibBundle];
	if (self) {
		self.layersByName = [[self class] layersByName];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		self.layersByName = [[self class] layersByName];
	}
	return self;
}

+ (NSDictionary *)layersByName {
	static NSDictionary *layers = nil;
	layers = @{
		kCenterName		 : [[self class] layerWithName:kCenterName hue:0.0 saturation:0.0 brightness:0.5],
		kTopLeftName	 : [[self class] layerWithName:kTopLeftName hue:0.888 saturation:0.885 brightness:0.988],
		kTopName		 : [[self class] layerWithName:kTopName hue:0.990 saturation:0.948 brightness:0.988],
		kTopRightName	 : [[self class] layerWithName:kTopRightName hue:0.082 saturation:0.854 brightness:0.992],
		kRightName		 : [[self class] layerWithName:kRightName hue:0.126 saturation:0.815 brightness:0.996],
		kBottomRightName : [[self class] layerWithName:kBottomRightName hue:0.206 saturation:0.794 brightness:0.992],
		kBottomName		 : [[self class] layerWithName:kBottomName hue:0.338 saturation:0.771 brightness:0.804],
		kBottomLeftName	 : [[self class] layerWithName:kBottomLeftName hue:0.591 saturation:0.917 brightness:0.949],
		kLeftName		 : [[self class] layerWithName:kLeftName hue:0.676 saturation:0.870 brightness:0.784]
	};
	return layers;
}

+ (CALayer *)layerWithName:(NSString *)name hue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness {
	CAGradientLayer *layer = [CAGradientLayer layer];

#if TARGET_OS_IPHONE
	UIColor *whiteColor = [UIColor colorWithWhite:1.0 alpha:1.0];
	UIColor *blackColor = [UIColor colorWithWhite:0.0 alpha:1.0];
	layer.startPoint = CGPointMake(0.5, 0.0);
	layer.endPoint = CGPointMake(0.5, 1.0);
	layer.backgroundColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1.0].CGColor;
	layer.borderColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness * 0.75 alpha:1.0].CGColor;
#else
	NSColor *whiteColor = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
	NSColor *blackColor = [NSColor colorWithCalibratedWhite:0.0 alpha:1.0];
	layer.startPoint = CGPointMake(0.5, 1.0);
	layer.endPoint = CGPointMake(0.5, 0.0);
	layer.backgroundColor = [NSColor colorWithCalibratedHue:hue saturation:saturation brightness:brightness alpha:1.0].CGColor;
	layer.borderColor = [NSColor colorWithCalibratedHue:hue saturation:saturation brightness:brightness * 0.75 alpha:1.0].CGColor;
#endif
	layer.borderWidth = 1.0;
	layer.cornerRadius = 5.0;
	layer.colors = @[
	  (id)[whiteColor colorWithAlphaComponent:0.5].CGColor,
	  (id)[whiteColor colorWithAlphaComponent:0.1].CGColor,
	  (id)[blackColor colorWithAlphaComponent:0.0].CGColor,
	  (id)[blackColor colorWithAlphaComponent:0.1].CGColor
	];
	layer.locations = @[@0.0, @0.5, @0.51, @1.0];
	layer.name = name;
	return layer;
}

#if TARGET_OS_IPHONE

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation; {
	return YES;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupView];
	[self setupSuperlayer:self.contentView.layer];
}

#else

- (void)setView:(NSView *)view {
	[super setView:view];
	[self setupView];
}

- (void)loadView {
	[super loadView];
	[self setupView];
}

#endif

- (void)setupView {	
	CGFloat centerWidth = 100.0;
	CGFloat centerHeight = 50.0;
	
#if TARGET_OS_IPHONE
	self.view.layer.backgroundColor = [UIColor lightGrayColor].CGColor;
	self.slider.value = centerHeight;
#else
	self.contentView.layer = [CALayer layer];
	self.contentView.wantsLayer = YES;
	
	self.view.layer = [CALayer layer];
	self.view.wantsLayer = YES;
	self.view.layer.backgroundColor = [NSColor lightGrayColor].CGColor;
	self.slider.doubleValue = centerHeight;
#endif
	
	CALayer *center = self.layersByName[kCenterName];
	center.frame = CGRectMake(0.0, 0.0, centerWidth, centerHeight);
	
	[self setupSuperlayer:self.contentView.layer];
}

- (void)setupSuperlayer:(CALayer *)superlayer {
	superlayer.name = @"super";

	superlayer.actions = @{@"sublayers" : [NSNull null]};
	
	CAConstraintLayoutManager *layoutManager = [CAConstraintLayoutManager layoutManager];
	
	NSDictionary *layersByName = self.layersByName;
	
#if TARGET_OS_IPHONE
	CGFloat topOffset = 10.0;
#else
	CGFloat topOffset = 0.0;
#endif
    
	CALayer *center = layersByName[kCenterName];
	[center addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:kSuperName attribute:kCAConstraintMidY]];
	[center addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:kSuperName attribute:kCAConstraintMidX]];
	[superlayer addSublayer:center];
	
	CALayer *topLeft = self.layersByName[kTopLeftName];
	[topLeft addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:kLeftName attribute:kCAConstraintWidth]];
	[topLeft addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX  relativeTo:kLeftName attribute:kCAConstraintMidX]];
	[topLeft addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY  relativeTo:kLeftName attribute:kCAConstraintMinY offset:-10]];
	[topLeft addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:kSuperName attribute:kCAConstraintMinY offset:10 + topOffset]];
	[superlayer addSublayer:topLeft];
	
	CALayer *top = layersByName[kTopName];
	[top addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:kCenterName attribute:kCAConstraintWidth]];
	[top addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX  relativeTo:kCenterName attribute:kCAConstraintMidX]];
	[top addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY  relativeTo:kCenterName attribute:kCAConstraintMinY offset:-10.0]];
	[top addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY  relativeTo:kSuperName  attribute:kCAConstraintMinY offset:10.0 + topOffset]];
	[superlayer addSublayer:top];
	
	CALayer *topRight = layersByName[kTopRightName];
	[topRight addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:kRightName attribute:kCAConstraintWidth]];
	[topRight addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX  relativeTo:kRightName attribute:kCAConstraintMidX]];
	[topRight addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY  relativeTo:kRightName attribute:kCAConstraintMinY offset:-10]];
	[topRight addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY  relativeTo:kSuperName attribute:kCAConstraintMinY offset:10 + topOffset]];
	[superlayer addSublayer:topRight];

	CALayer *right = layersByName[kRightName];
	[right addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:kCenterName attribute:kCAConstraintHeight scale:4.0 offset:0]];
	[right addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY   relativeTo:kCenterName attribute:kCAConstraintMidY]];
	[right addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX   relativeTo:kCenterName attribute:kCAConstraintMaxX offset:10]];
	[right addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX   relativeTo:kSuperName  attribute:kCAConstraintMaxX offset:-10]];
	[superlayer addSublayer:right];

	CALayer *bottomRight = layersByName[kBottomRightName];
	[bottomRight addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:kRightName attribute:kCAConstraintWidth]];
	[bottomRight addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX  relativeTo:kRightName attribute:kCAConstraintMidX]];
	[bottomRight addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY  relativeTo:kRightName attribute:kCAConstraintMaxY offset:10]];
	[bottomRight addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY  relativeTo:kSuperName attribute:kCAConstraintMaxY offset:-10]];
	[superlayer addSublayer:bottomRight];

	CALayer *bottom = layersByName[kBottomName];
	[bottom addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:kCenterName attribute:kCAConstraintWidth]];
	[bottom addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX  relativeTo:kCenterName attribute:kCAConstraintMidX]];
	[bottom addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY  relativeTo:kCenterName attribute:kCAConstraintMaxY offset:10.0]];
	[bottom addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY  relativeTo:kSuperName  attribute:kCAConstraintMaxY offset:-10.0]];
	[superlayer addSublayer:bottom];

	CALayer *bottomLeft = layersByName[kBottomLeftName];
	[bottomLeft addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:kLeftName  attribute:kCAConstraintWidth]];
	[bottomLeft addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX  relativeTo:kLeftName  attribute:kCAConstraintMidX]];
	[bottomLeft addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY  relativeTo:kLeftName  attribute:kCAConstraintMaxY offset:10]];
	[bottomLeft addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY  relativeTo:kSuperName attribute:kCAConstraintMaxY offset:-10]];
	[superlayer addSublayer:bottomLeft];

	CALayer *left = layersByName[kLeftName];
	[left addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:kCenterName attribute:kCAConstraintHeight scale:3.0 offset:0]];
	[left addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY   relativeTo:kCenterName attribute:kCAConstraintMidY]];
	[left addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX   relativeTo:kCenterName attribute:kCAConstraintMinX offset:-10]];
	[left addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX   relativeTo:kSuperName  attribute:kCAConstraintMinX offset:10]];
	[superlayer addSublayer:left];
	
	superlayer.layoutManager = layoutManager;
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
		[center setBounds:CGRectMake(0.0, 0.0, 150.0, 50.0)];
	});
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
		[center removeFromSuperlayer];
	});
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
		[center setBounds:CGRectMake(0.0, 0.0, 50.0, 50.0)];
		[superlayer addSublayer:center];
	});
}

- (IBAction)changeCenterHeight:(id)sender {
	CALayer *center = self.layersByName[kCenterName];
#if TARGET_OS_IPHONE
	CGFloat height = self.slider.value;
#else
	CGFloat height = self.slider.doubleValue;
#endif
	CGRect frame = [center frame];
	frame.size.height = floor(height + 0.5);
	center.frame = frame;
}

@end
