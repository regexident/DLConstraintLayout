//
//  DLCLConstraintLayoutSolver.m
//  DLConstraintLayout
//
//  Created by vesche on 4/9/13.
//  Copyright (c) 2013 Regexident. All rights reserved.
//

#import "DLCLConstraintLayoutSolver.h"

#import <QuartzCore/QuartzCore.h>

#import "DLConstraintLayout+Protected.h"
#import "DLCLConstraintLayoutNode.h"
#import "CALayer+DLConstraintLayout.h"

@interface DLCLConstraintLayoutSolver ()

@property (readwrite, unsafe_unretained, nonatomic) CALayer *layer;
@property (readwrite, strong, nonatomic) NSMutableArray *nodes;

@end

@implementation DLCLConstraintLayoutSolver

- (id)initWithLayer:(CALayer *)layer {
	self = [self init];
	if (self) {
		self.layer = layer;
		self.nodes = [NSMutableArray array];
		
		[self generateNodesForLayer:self.layer];
		[self addNodeDependencies];
		[self sortNodesTopologically];
		BOOL validLayout = [self validateSortedNodes];
		NSAssert(validLayout, @"Circle detected. Constraint dependencies must not form cycles.");
	}
	return self;
}

+ (instancetype)solverWithLayer:(CALayer *)layer {
	return DLCL_AUTORELEASE([[self alloc] initWithLayer:layer]);
}

- (void)solveLayout {
	CALayer *superlayer = self.layer;
	for (DLCLConstraintLayoutNode *node in self.nodes) {
		[self solveNode:node inSuperlayer:superlayer];
	}
}

- (void)generateNodesForLayer:(CALayer *)layer {
	[self.nodes removeAllObjects];
	for (CALayer *sublayer in layer.sublayers) {
		DLCLConstraintLayoutNode *axisNodes[] = {
			[DLCLConstraintLayoutNode nodeWithAxis:DLCLConstraintAxisX forLayer:sublayer],
			[DLCLConstraintLayoutNode nodeWithAxis:DLCLConstraintAxisY forLayer:sublayer]
		};
		for (DLCLConstraint *constraint in sublayer.constraints) {
			DLCLConstraintAxis axis;
			if (![constraint getAxis:&axis axisAttribute:NULL]) {
				continue;
			}
			[axisNodes[axis] addConstraint:constraint];
		}
		if ([axisNodes[DLCLConstraintAxisX].constraints count]) {
			[self.nodes addObject:axisNodes[DLCLConstraintAxisX]];
		}
		if ([axisNodes[DLCLConstraintAxisY].constraints count]) {
			[self.nodes addObject:axisNodes[DLCLConstraintAxisY]];
		}
	}
}

- (void)addNodeDependencies {
	NSMutableDictionary *nodesByAxis[] = {
		[NSMutableDictionary dictionary],
		[NSMutableDictionary dictionary]
	};
	// Create lookup dictionaries:
	for (DLCLConstraintLayoutNode *node in self.nodes) {
		NSMutableDictionary *nodesByLayer = nodesByAxis[node.axis];
		NSValue *pointerValue = [NSValue valueWithPointer:(void *)node.layer];
		NSMutableSet *nodes = nodesByLayer[pointerValue];
		if (!nodes) {
			nodes = [NSMutableSet set];
			nodesByLayer[pointerValue] = nodes;
		}
		[nodes addObject:node];
	}
	for (DLCLConstraintLayoutNode *node in self.nodes) {
		CALayer *superlayer = node.layer.superlayer;
		for (DLCLConstraint *constraint in node.constraints) {
			CALayer *sourceLayer = [constraint sourceLayerInSuperlayer:superlayer];
			if (!sourceLayer) {
				continue;
			}
			DLCLConstraintAxis sourceAxis;
			if (![constraint getSourceAxis:&sourceAxis axisAttribute:NULL]) {
				continue;
			}
			NSMutableDictionary *nodesByLayer = nodesByAxis[sourceAxis];
			NSMutableArray *sourceNodes = [nodesByLayer objectForKey:[NSValue valueWithPointer:(void *)sourceLayer]];
			for (DLCLConstraintLayoutNode *sourceNode in sourceNodes) {
				if ([node hasDependencyTo:sourceNode]) {
					[node addDependencyTo:sourceNode];
				}
			}
		}
	}
}

- (void)sortNodesTopologically {
	NSArray *nodes = [NSArray arrayWithArray:self.nodes];
	[self.nodes removeAllObjects];
	NSMutableArray *queue = [NSMutableArray array];
	for (DLCLConstraintLayoutNode *node in nodes) {
		if (![node.incoming count]) {
			[queue addObject:node];
		}
	}
	while ([queue count]) {
		DLCLConstraintLayoutNode *node = queue[0];
		[queue removeObjectAtIndex:0];
		[self.nodes addObject:node];
		for (DLCLConstraintLayoutNode *outgoingNode in [NSSet setWithSet:node.outgoing]) {
			[outgoingNode removeDependencyTo:node];
			if (![outgoingNode.incoming count]) {
				[queue addObject:outgoingNode];
			}
		}
	}
}

- (BOOL)validateSortedNodes {
	for (DLCLConstraintLayoutNode *node in self.nodes) {
		if ([node.outgoing count] || [node.incoming count]) {
			return NO;
		}
	}
	return YES;
}

- (void)solveNode:(DLCLConstraintLayoutNode *)node inSuperlayer:(CALayer *)superlayer {
	CALayer *layer = node.layer;
	if (!layer) {
		return;
	}
	CGRect frame = layer.frame;
	NSMutableDictionary *sourceValuesByAxisAttribute = [NSMutableDictionary dictionary];
	int axisAttributesMask = 0x0;
	for (DLCLConstraint *constraint in node.constraints) {
		DLCLConstraintAxisAttribute axisAttribute;
		if (![constraint getAxis:NULL axisAttribute:&axisAttribute]) {
			continue;
		}
		DLCLConstraintAxis sourceAxis;
		DLCLConstraintAxisAttribute sourceAxisAttribute;
		if (![constraint getSourceAxis:&sourceAxis axisAttribute:&sourceAxisAttribute]) {
			continue;
		}
		CALayer *sourceLayer = [constraint sourceLayerInSuperlayer:superlayer];
		if (!sourceLayer) {
			continue;
		}
		axisAttributesMask |= (0x1 << (int)axisAttribute);
		CGRect sourceFrame = sourceLayer.frame;
		typedef CGFloat DLCLRectFunction(CGRect rect);
		DLCLRectFunction *rectFunctions[] = {
			&CGRectGetMinX, &CGRectGetMidX, &CGRectGetMaxX, &CGRectGetWidth,
			&CGRectGetMinY, &CGRectGetMidY, &CGRectGetMaxY, &CGRectGetHeight
		};
		CGFloat sourceAttributeValue = rectFunctions[constraint.sourceAttribute](sourceFrame);
		sourceValuesByAxisAttribute[@((int)axisAttribute)] = @((sourceAttributeValue * constraint.scale) + constraint.offset);
	}
	layer.frame = [[self class] frame:(CGRect)frame afterSettingAttributeValues:sourceValuesByAxisAttribute onAxis:node.axis forMask:axisAttributesMask];
}

+ (CGRect)frame:(CGRect)frame afterSettingAttributeValues:(NSDictionary *)attributeValues onAxis:(DLCLConstraintAxis)axis forMask:(int)axisAttributesMask {
	NSNumber *minKey = @((int)DLCLConstraintAxisAttributeMin);
	NSNumber *midKey = @((int)DLCLConstraintAxisAttributeMid);
	NSNumber *maxKey = @((int)DLCLConstraintAxisAttributeMax);
	NSNumber *sizeKey = @((int)DLCLConstraintAxisAttributeSize);
	CGFloat minValue = (axis == DLCLConstraintAxisX) ? CGRectGetMinX(frame) : CGRectGetMinY(frame);
	CGFloat sizeValue = (axis == DLCLConstraintAxisX) ? CGRectGetWidth(frame) : CGRectGetHeight(frame);
	
	if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMin)) {
		minValue = [attributeValues[minKey] doubleValue]; // min
		if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMid)) { // min & mid
			sizeValue = ([attributeValues[midKey] doubleValue] - minValue) * 2;
		} else if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMax)) { // min & max
			sizeValue = ([attributeValues[maxKey] doubleValue] - minValue);
		} else if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeSize)) { // min & size
			sizeValue = [attributeValues[sizeKey] doubleValue];
		}
	} else if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeSize)) {
		sizeValue = [attributeValues[sizeKey] doubleValue]; // size
		if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMid)) { // size & mid
			minValue = [attributeValues[midKey] doubleValue] - (sizeValue / 2);
		} else if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMax)) { // size & max
			minValue = [attributeValues[maxKey] doubleValue] - sizeValue;
		}
	} else if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMid)) {
		minValue = [attributeValues[midKey] doubleValue] - (sizeValue / 2); // mid
		if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMax)) { // mid & max
			sizeValue = ([attributeValues[maxKey] doubleValue] - [attributeValues[midKey] doubleValue]) * 2;
			minValue = [attributeValues[maxKey] doubleValue] - sizeValue;
		}
	} else if (axisAttributesMask & (0x1 << DLCLConstraintAxisAttributeMax)) {
		minValue = [attributeValues[maxKey] doubleValue] - sizeValue; // max
	}
	if (axis == DLCLConstraintAxisX) {
		frame.origin.x = minValue;
		frame.size.width = sizeValue;
	} else {
		frame.origin.y = minValue;
		frame.size.height = sizeValue;
	}
	return frame;
}

@end
