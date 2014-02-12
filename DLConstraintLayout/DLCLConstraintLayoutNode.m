//
//  DLCLConstraintLayoutNode.m
//  DLConstraintLayout
//
//  Created by vesche on 4/9/13.
//  Copyright (c) 2013 Regexident. All rights reserved.
//

#import "DLCLConstraintLayoutNode.h"

#import "DLConstraintLayout+Protected.h"

@interface DLCLConstraintLayoutNode ()

@property (readwrite, weak, nonatomic) CALayer *layer;
@property (readwrite, assign, nonatomic) DLCLConstraintAxis axis;
@property (readwrite, strong, nonatomic) NSMutableSet *mutableConstraints;
@property (readwrite, strong, nonatomic) NSMutableSet *mutableIncoming;
@property (readwrite, strong, nonatomic) NSMutableSet *mutableOutgoing;

@end

@implementation DLCLConstraintLayoutNode

- (id)initWithAxis:(DLCLConstraintAxis)axis forLayer:(CALayer *)layer {
	self = [self init];
	if (self) {
		self.layer = layer;
		self.axis = axis;
		self.mutableConstraints = [NSMutableSet set];
		self.mutableIncoming = [NSMutableSet set];
		self.mutableOutgoing = [NSMutableSet set];
	}
	return self;
}

+ (id)nodeWithAxis:(DLCLConstraintAxis)axis forLayer:(CALayer *)layer {
	return [[self alloc] initWithAxis:axis forLayer:layer];
}

- (NSSet *)constraints {
	return [NSSet setWithSet:self.mutableConstraints];
}

- (void)addConstraint:(DLCLConstraint *)constraint {
	[self.mutableConstraints addObject:constraint];
}

- (NSSet *)incoming {
	return [NSSet setWithSet:self.mutableIncoming];
}

- (NSSet *)outgoing {
	return [NSSet setWithSet:self.mutableOutgoing];
}

- (BOOL)hasDependencyTo:(DLCLConstraintLayoutNode *)node {
	CALayer *superlayer = self.layer.superlayer;
	BOOL hasDependency = NO;
	for (DLCLConstraint *constraint in self.constraints) {
		CALayer *sourceLayer = [constraint sourceLayerInSuperlayer:superlayer];
		if (sourceLayer != node.layer) {
			continue;
		}
		DLCLConstraintAxis sourceAxis;
		if (![constraint getSourceAxis:&sourceAxis axisAttribute:NULL]) {
			continue;
		}
		for (DLCLConstraint *otherConstraint in self.constraints) {
			DLCLConstraintAxis otherAxis;
			if (![otherConstraint getSourceAxis:&otherAxis axisAttribute:NULL]) {
				continue;
			}
			if (sourceAxis == otherAxis) {
				hasDependency = YES;
				break;
			}
		}
	}
	return hasDependency;
}

- (void)addDependencyTo:(DLCLConstraintLayoutNode *)node{
	NSAssert(node, @"Method argument 'node' must not be nil.");
	[self.mutableIncoming addObject:node];
	[node.mutableOutgoing addObject:self];
}

- (void)removeDependencyTo:(DLCLConstraintLayoutNode *)node {
	NSAssert(node, @"Method argument 'node' must not be nil.");
	[self.mutableIncoming removeObject:node];
	[node.mutableOutgoing removeObject:self];
}

- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"<%@ %p ", [self class], self];
	[description appendString:@"\nconstraints:\n"];
	[description appendString:[self.constraints description]];
	[description appendString:@"\nincoming:\n"];
	[description appendString:[self.incoming description]];
	[description appendString:@"\noutgoing:\n"];
	[description appendString:[self.outgoing description]];
	[description appendString:@"\n>"];
	return description;
}

@end
