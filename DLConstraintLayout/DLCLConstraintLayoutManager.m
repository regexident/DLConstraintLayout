//
//  DLCLConstraintLayoutManager.m
//  DLConstraintLayout
//
//  Created by Vincent Esche on 3/14/13.
//  Copyright (c) 2013 Vincent Esche. All rights reserved.
//

#import "DLCLConstraintLayoutManager.h"

#import <objc/runtime.h>

#import "CALayer+DLConstraintLayout.h"
#import "DLCLConstraint.h"
#import "DLCLConstraint+Protected.h"
#import "DLConstraintLayout+Protected.h"

#import "DLCLConstraintLayoutSolver.h"

@interface DLCLConstraintLayoutManager ()

@property (readwrite, strong, nonatomic) NSMapTable *solversByLayer;
@property (readwrite, strong, nonatomic) NSHashTable *layersNeedingGraphUpdate;

@end

@implementation DLCLConstraintLayoutManager

+ (id)alloc {
	static BOOL didCheckNativeClass = NO;
	static Class nativeClass = Nil;
	static BOOL conformsToProtocol = YES;
	if (!didCheckNativeClass) {
		didCheckNativeClass = YES;
		nativeClass = NSClassFromString(kDLCAConstraintLayoutManagerClassName);
		conformsToProtocol = nativeClass && DLCLClassImplementsProtocol(nativeClass, @protocol(DLCLConstraintLayoutManager));
	}
	return (conformsToProtocol) ? [nativeClass alloc] : [super alloc];
}

+ (instancetype)layoutManager {
	static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		if (!instance) {
			instance = [[self alloc] init];
		}
	});
	return instance;
}

- (id)init {
	self = [super init];
	if (self) {
		self.solversByLayer = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsObjectPointerPersonality];
	}
	return self;
}

#if !__has_feature(objc_arc)

- (void)dealloc {
	self.solversByLayer = nil;
	[super dealloc];
}

#endif

- (void)invalidateLayoutOfLayer:(CALayer *)layer {
	NSAssert(layer, @"Method argument 'layer' must not be nil.");
	[self updateSolverForLayer:layer];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
	NSAssert(layer, @"Method argument 'layer' must not be nil.");
#if defined(DEBUG) && defined(DLCL_BENCHMARK) && DLCL_BENCHMARK > 0
	NSUInteger iterations = DLCL_BENCHMARK;
	NSDate *startDate = [NSDate date];
	for (NSUInteger iteration = 0; iteration < iterations; iteration++) {
		[[self solverForLayer:layer] solveLayout];
	}
	NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:startDate];
	NSLog(@"Took %.5f seconds to run %s %d times (@ %.5f seconds each, on average).", interval, __PRETTY_FUNCTION__, iterations, interval / iterations);
#else
	[[self solverForLayer:layer] solveLayout];
#endif
}

- (CGSize)preferredSizeOfLayer:(CALayer *)layer {
	NSAssert(layer, @"Method argument 'layer' must not be nil.");
	return layer.bounds.size;
}

- (void)registerSolverForLayer:(CALayer *)layer {
	NSAssert(layer, @"Method argument 'layer' must not be nil.");
	[self.solversByLayer setObject:[NSNull null] forKey:layer];
}

- (void)unregisterSolverForLayer:(CALayer *)layer {
	NSAssert(layer, @"Method argument 'layer' must not be nil.");
	[self.solversByLayer removeObjectForKey:layer];
}

- (void)updateSolverForLayer:(CALayer *)layer {
	[self unregisterSolverForLayer:layer];
	[self registerSolverForLayer:layer];
}

- (DLCLConstraintLayoutSolver *)solverForLayer:(CALayer *)layer {
	NSAssert(layer, @"Method argument 'layer' must not be nil.");
	DLCLConstraintLayoutSolver *solver = [self.solversByLayer objectForKey:layer];
	if (!solver) {
		return nil;
	}
	if ((NSNull *)solver == [NSNull null]) {
		solver = [DLCLConstraintLayoutSolver solverWithLayer:layer];
		[self.solversByLayer setObject:solver forKey:layer];		
	}
	return solver;
}

@end
