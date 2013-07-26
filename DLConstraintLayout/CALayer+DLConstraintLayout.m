//
//  CALayer+DLConstraintLayout.m
//  DLConstraintLayout
//
//  Created by Vincent Esche on 3/13/13.
//  Copyright (c) 2013 Vincent Esche. All rights reserved.
//

#import "CALayer+DLConstraintLayout.h"

#import <objc/runtime.h>
#import "DLConstraintLayout+Protected.h"

@interface DLCLConstraintLayoutManager ()

- (void)registerSolverForLayer:(CALayer *)superlayer;
- (void)unregisterSolverForLayer:(CALayer *)superlayer;
- (void)updateSolverForLayer:(CALayer *)layer;

@end

void * const kDLCLConstraintLayoutMarkerKey = (void * const) &kDLCLConstraintLayoutMarkerKey;
void * const kDLCLConstraintLayoutManagerKey = (void * const) &kDLCLConstraintLayoutManagerKey;
void * const kDLCLConstraintLayoutConstraintsKey = (void * const) &kDLCLConstraintLayoutConstraintsKey;

void swizzleOrAddInstanceMethod_dlcl(Class class, SEL selectorA, SEL selectorB) {
	Method methodA = class_getInstanceMethod(class, selectorA);
	Method methodB = class_getInstanceMethod(class, selectorB);
	if (methodA) {
		method_exchangeImplementations(methodA, methodB);
	} else {
		class_addMethod(class, selectorA, class_getMethodImplementation(class, selectorB), method_getTypeEncoding(methodB));
	}
}

@implementation CALayer (DLConstraintLayout)

+ (void)load {
	[CALayer enableConstraintLayout];
}

+ (BOOL)enableConstraintLayout {
	Class constraintClass = NSClassFromString(kDLCAConstraintClassName);
	Class constraintLayoutManagerClass = NSClassFromString(kDLCAConstraintLayoutManagerClassName);
	BOOL constraintClassImplementsProtocol = constraintClass && DLCLClassImplementsProtocol(constraintClass, @protocol(DLCLConstraint));
	BOOL constraintLayoutManagerClassImplementsProtocol = constraintLayoutManagerClass && DLCLClassImplementsProtocol(constraintLayoutManagerClass, @protocol(DLCLConstraintLayoutManager));
	if (constraintClassImplementsProtocol && constraintLayoutManagerClassImplementsProtocol) {
		return NO;
	} else if (constraintClass != Nil) {
		[[NSException exceptionWithName:@"DLCLConstraintLayoutClassCollision"
								 reason:@"Found class 'CAConstraint' with incompatible interface."
							   userInfo:nil] raise];
	} else if (constraintLayoutManagerClass != Nil) {
		[[NSException exceptionWithName:@"DLCLConstraintLayoutClassCollision"
								 reason:@"Found class 'CAConstraintLayoutManager' with incompatible interface."
							   userInfo:nil] raise];
	}
//	NSAssert(!NSClassFromString(@"CAConstraint"), @"Class CAConstraint already exists in runtime.");
//	NSAssert(!NSClassFromString(@"CAConstraintLayoutManager"), @"Class CAConstraintLayoutManager already exists in runtime.");
	
	Class layerClass = [CALayer class];
	
	if (objc_getAssociatedObject(layerClass, kDLCLConstraintLayoutMarkerKey)) {
		return YES; // Class already swizzled.
	}
	
	// Set swizzling marker.
	objc_setAssociatedObject(layerClass, kDLCLConstraintLayoutMarkerKey, @YES, OBJC_ASSOCIATION_ASSIGN);
	
	// Add constraint layout methods:
	swizzleOrAddInstanceMethod_dlcl(layerClass, @selector(layoutManager), @selector(layoutManager_dlcl));
	swizzleOrAddInstanceMethod_dlcl(layerClass, @selector(setLayoutManager:), @selector(setLayoutManager_dlcl:));
	swizzleOrAddInstanceMethod_dlcl(layerClass, @selector(constraints), @selector(constraints_dlcl));
	swizzleOrAddInstanceMethod_dlcl(layerClass, @selector(setConstraints:), @selector(setConstraints_dlcl:));
	swizzleOrAddInstanceMethod_dlcl(layerClass, @selector(addConstraint:), @selector(addConstraint_dlcl:));
	
	// Swizzle custom layout method:
	swizzleOrAddInstanceMethod_dlcl(layerClass, @selector(layoutSublayers), @selector(layoutSublayers_dlcl));
		
	return YES;
}

- (id)layoutManager_dlcl {
	return objc_getAssociatedObject(self, kDLCLConstraintLayoutManagerKey);
}

- (void)setLayoutManager_dlcl:(id)layoutManager {
	if (layoutManager) {
		[(DLCLConstraintLayoutManager *)layoutManager registerSolverForLayer:self];
	} else {
		[(DLCLConstraintLayoutManager *)layoutManager unregisterSolverForLayer:self];
	}
	objc_setAssociatedObject(self, kDLCLConstraintLayoutManagerKey, layoutManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self setNeedsLayout];
}

- (NSArray *)constraints_dlcl {
	NSMutableSet *constraintsSet = objc_getAssociatedObject(self, kDLCLConstraintLayoutConstraintsKey);
	return (constraintsSet) ? [constraintsSet allObjects] : @[];
}

- (void)setConstraints_dlcl:(NSArray *)constraints {
	NSMutableSet *constraintsSet = [NSMutableSet setWithArray:constraints];
	objc_setAssociatedObject(self, kDLCLConstraintLayoutConstraintsKey, constraintsSet, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self.layoutManager updateSolverForLayer:self.superlayer];
	[self.superlayer setNeedsLayout];
}

- (void)addConstraint_dlcl:(DLCLConstraint *)constraint {
	NSAssert(constraint, @"Method argument constraint must not be nil.");
	NSMutableSet *constraintsSet = objc_getAssociatedObject(self, kDLCLConstraintLayoutConstraintsKey);
	[self willChangeValueForKey:@"constraints"];
	if (!constraintsSet) {
		constraintsSet = [NSMutableSet set];
		objc_setAssociatedObject(self, kDLCLConstraintLayoutConstraintsKey, constraintsSet, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	[constraintsSet addObject:constraint];
	[self didChangeValueForKey:@"constraints"];
	[self.layoutManager updateSolverForLayer:self.superlayer];
	[self.superlayer setNeedsLayout];
}

- (void)layoutSublayers_dlcl {
	[self layoutSublayers_dlcl]; // calls original implementation after swizzling
	[self.layoutManager layoutSublayersOfLayer:self];
}

@end