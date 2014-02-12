//
//  DLCLConstraint.m
//  DLConstraintLayout
//
//  Created by Vincent Esche on 3/14/13.
//  Copyright (c) 2013 Vincent Esche. All rights reserved.
//

#import "DLCLConstraint.h"
#import "DLCLConstraint+Protected.h"

#import "DLConstraintLayout+Protected.h"

NSString *DLCLConstraintAttributeMaskDescription(int attributeMask) {
	NSString *strings[] = {@"minX", @"midX", @"maxX", @"width", @"minY", @"midY", @"maxY", @"height"};
	NSMutableArray *attributeValues = [NSMutableArray array];
	int i = 0;
	for (int z = 128; z > 0; z >>= 1, i++) {
		BOOL isSetBit = (attributeMask & z) == z;
		if (isSetBit) {
			[attributeValues insertObject:strings[7 - i] atIndex:0];
		}
	}
	return [NSString stringWithFormat:@"{%@}", [attributeValues componentsJoinedByString:@", "]];
}

@interface DLCLConstraint ()

@property (readwrite, assign, nonatomic) DLCLConstraintAttribute attribute;
@property (readwrite, assign, nonatomic) CGFloat offset;
@property (readwrite, assign, nonatomic) CGFloat scale;
@property (readwrite, assign, nonatomic) DLCLConstraintAttribute sourceAttribute;
@property (readwrite, copy, nonatomic) NSString *sourceName;

@end

@implementation DLCLConstraint

+ (instancetype)constraintWithAttribute:(DLCLConstraintAttribute)attribute relativeTo:(NSString *)sourceLayer attribute:(DLCLConstraintAttribute)sourceAttribute scale:(CGFloat)scale offset:(CGFloat)offset {
	return [(DLCLConstraint *)[self alloc] initWithAttribute:attribute
                                                  relativeTo:sourceLayer
                                                   attribute:sourceAttribute
                                                       scale:scale
                                                      offset:offset];
}

+ (instancetype)constraintWithAttribute:(DLCLConstraintAttribute)attribute relativeTo:(NSString *)sourceLayer attribute:(DLCLConstraintAttribute)sourceAttribute offset:(CGFloat)offset {
	return [(DLCLConstraint *)[self alloc] initWithAttribute:attribute
                                                  relativeTo:sourceLayer
                                                   attribute:sourceAttribute
                                                       scale:1.0
                                                      offset:offset];
}

+ (instancetype)constraintWithAttribute:(DLCLConstraintAttribute)attribute relativeTo:(NSString *)sourceLayer attribute:(DLCLConstraintAttribute)sourceAttribute {
	return [(DLCLConstraint *)[self alloc] initWithAttribute:attribute
                                                  relativeTo:sourceLayer
                                                   attribute:sourceAttribute
                                                       scale:1.0
                                                      offset:0.0];
}

+ (id)alloc {
	static BOOL didCheckNativeClass = NO;
	static Class nativeClass = Nil;
	static BOOL conformsToProtocol = YES;
	if (!didCheckNativeClass) {
		didCheckNativeClass = YES;
		nativeClass = NSClassFromString(kDLCAConstraintClassName);
		conformsToProtocol = nativeClass && DLCLClassImplementsProtocol(nativeClass, @protocol(DLCLConstraint));
	}
	return (conformsToProtocol) ? [nativeClass alloc] : [super alloc];
}

- (id)initWithAttribute:(DLCLConstraintAttribute)attribute relativeTo:(NSString *)sourceLayer attribute:(DLCLConstraintAttribute)sourceAttribute scale:(CGFloat)scale offset:(CGFloat)offset {
	NSAssert(attribute >= kDLCLConstraintMinX && attribute <= kDLCLConstraintHeight, @"Method argument 'attribute' must be of known value.");
	NSAssert(sourceAttribute >= kDLCLConstraintMinX && sourceAttribute <= kDLCLConstraintHeight, @"Method argument 'sourceAttribute' must be of known value.");
	self = [self init];
	if (self) {
		self.attribute = attribute;
		self.sourceName = sourceLayer;
		self.sourceAttribute = sourceAttribute;
		self.offset = offset;
		self.scale = scale;
	}
	return self;
}

- (BOOL)isEqualToConstraint:(DLCLConstraint *)constraint {
	return (self.attribute == constraint.attribute &&
			self.offset == constraint.offset &&
			self.scale == constraint.scale &&
			self.sourceAttribute == constraint.sourceAttribute &&
			[self.sourceName isEqualToString:constraint.sourceName]);
}

- (BOOL)isEqual:(id)object {
	if (![object isMemberOfClass:[self class]]) {
		return NO;
	}
	return [self isEqualToConstraint:(DLCLConstraint *)object];
}

+ (BOOL)getAxis:(DLCLConstraintAxis *)axisBuffer axisAttribute:(DLCLConstraintAxisAttribute *)axisAttributeBuffer fromAttribute:(DLCLConstraintAttribute)attribute {
	if (attribute < kDLCLConstraintMinX || attribute > kDLCLConstraintHeight) {
		return NO;
	}
	DLCLConstraintAxis axis = (attribute <= kDLCLConstraintWidth) ? DLCLConstraintAxisX : DLCLConstraintAxisY;
	if (axisBuffer) {
		*axisBuffer = axis;
	}
	if (axisAttributeBuffer) {
		DLCLConstraintAxisAttribute axisAttribute = (DLCLConstraintAxisAttribute)((axis == DLCLConstraintAxisX) ? attribute : attribute - 4);
		*axisAttributeBuffer = axisAttribute;
	}
	return YES;
}

- (BOOL)getAxis:(DLCLConstraintAxis *)axis axisAttribute:(DLCLConstraintAxisAttribute *)axisAttribute {
	return [[self class] getAxis:axis axisAttribute:axisAttribute fromAttribute:self.attribute];
}

- (BOOL)getSourceAxis:(DLCLConstraintAxis *)axis axisAttribute:(DLCLConstraintAxisAttribute *)axisAttribute {
	return [[self class] getAxis:axis axisAttribute:axisAttribute fromAttribute:self.sourceAttribute];
}

- (CALayer *)sourceLayerInSuperlayer:(CALayer *)superlayer {
	NSString *sourceName = self.sourceName;
	if (!sourceName || [sourceName isEqualToString:@"superlayer"]) {
		return superlayer;
	}
	CALayer *sourceLayer = nil;
	for (CALayer *sublayer in superlayer.sublayers) {
		if ([sublayer.name isEqualToString:sourceName]) {
			sourceLayer = sublayer;
			break;
		}
	}
	return sourceLayer;
}

- (NSUInteger)hash {
	return ((NSUInteger)self.attribute ^ (NSUInteger)self.offset ^ (NSUInteger)self.scale ^ (NSUInteger)self.sourceAttribute ^ [self.sourceName hash]);
}

- (NSString *)description {
	NSString *attributes[] = {@"minX", @"midX", @"maxX", @"width", @"minY", @"midY", @"maxY", @"height"};
	return [NSString stringWithFormat:@"<%@ %p attribute:%@ sourceAttribute:%@ offset:%.2f scale:%.2f sourceName:%@>",
			[self class],
			self,
			attributes[self.attribute],
			attributes[self.sourceAttribute],
			self.offset,
			self.scale,
			self.sourceName];
}

@end
