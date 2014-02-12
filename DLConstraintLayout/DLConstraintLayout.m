//
//  DLConstraintLayout.m
//  DLConstraintLayout
//
//  Created by Vincent Esche on 3/13/13.
//  Copyright (c) 2013 Vincent Esche. All rights reserved.
//

#import "DLConstraintLayout.h"

#import <objc/runtime.h>

NSString * const kDLCAConstraintClassName = @"CAConstraint";
NSString * const kDLCAConstraintLayoutManagerClassName = @"CAConstraintLayoutManager";

BOOL DLCLClassImplementsProtocolProperties(Class aClass, Protocol *aProtocol) {
	NSMutableDictionary *propertyAttributesByName = [NSMutableDictionary dictionary];
	BOOL implementsProtocol = YES;
	unsigned int classPropertiesCount = 0;
	objc_property_t *classProperties = class_copyPropertyList(aClass, &classPropertiesCount);
	for (NSUInteger i = 0; i < classPropertiesCount; i++) {
		NSString *propertyName = [NSString stringWithCString:property_getName(classProperties[i]) encoding:NSUTF8StringEncoding];
		NSString *propertyAttributes = [NSString stringWithCString:property_getAttributes(classProperties[i]) encoding:NSUTF8StringEncoding];
		propertyAttributesByName[propertyName] = propertyAttributes;
	}
	free(classProperties);
	unsigned int protocolPropertiesCount = 0;
	objc_property_t *protocolProperties = protocol_copyPropertyList(aProtocol, &protocolPropertiesCount);
	for (NSUInteger i = 0; i < protocolPropertiesCount; i++) {
		NSString *propertyName = [NSString stringWithCString:property_getName(protocolProperties[i]) encoding:NSUTF8StringEncoding];
		NSString *propertyAttributes = [NSString stringWithCString:property_getAttributes(protocolProperties[i]) encoding:NSUTF8StringEncoding];
		if (![propertyAttributesByName[propertyName] isEqualToString:propertyAttributes]) {
            NSLog(@"Property '%@' in class '%@' does not match protocol '%@'.", propertyName, NSStringFromClass(aClass), NSStringFromProtocol(aProtocol));
			implementsProtocol = NO;
			break;
		}
	}
	free(protocolProperties);
	return implementsProtocol;
}

BOOL DLCLClassImplementsProtocolMethods(Class aClass, Protocol *aProtocol, BOOL isInstanceMethod) {
	NSMutableDictionary *methodAttributesByName = [NSMutableDictionary dictionary];
	BOOL implementsProtocol = YES;
	unsigned int classMethodsCount = 0;
	struct objc_method_description *classMethods = protocol_copyMethodDescriptionList(aProtocol, YES, isInstanceMethod, &classMethodsCount);
	for (NSUInteger i = 0; i < classMethodsCount; i++) {
		NSString *methodName = NSStringFromSelector(classMethods[i].name);
		NSString *methodAttributes = [NSString stringWithCString:classMethods[i].types encoding:NSUTF8StringEncoding];
		methodAttributesByName[methodName] = methodAttributes;
	}
	free(classMethods);
	unsigned int protocolMethodsCount = 0;
	struct objc_method_description *protocolMethods = protocol_copyMethodDescriptionList(aProtocol, YES, isInstanceMethod, &protocolMethodsCount);
	for (NSUInteger i = 0; i < protocolMethodsCount; i++) {
		NSString *methodName = NSStringFromSelector(protocolMethods[i].name);
		NSString *methodAttributes = [NSString stringWithCString:protocolMethods[i].types encoding:NSUTF8StringEncoding];
		if (![methodAttributesByName[methodName] isEqualToString:methodAttributes]) {
            NSLog(@"Method '%@' in class '%@' does not match protocol '%@'.", methodName, NSStringFromClass(aClass), NSStringFromProtocol(aProtocol));
			implementsProtocol = NO;
			break;
		}
	}
	free(protocolMethods);
	return implementsProtocol;
}

BOOL DLCLClassImplementsProtocolClassMethods(Class aClass, Protocol *aProtocol) {
	return DLCLClassImplementsProtocolMethods(aClass, aProtocol, NO);
}

BOOL DLCLClassImplementsProtocolInstanceMethods(Class aClass, Protocol *aProtocol) {
	return DLCLClassImplementsProtocolMethods(aClass, aProtocol, YES);
}

BOOL DLCLClassImplementsProtocol(Class aClass, Protocol *aProtocol) {
	BOOL implementsProtocol = YES;
	implementsProtocol = implementsProtocol && DLCLClassImplementsProtocolProperties(aClass, aProtocol);
	implementsProtocol = implementsProtocol && DLCLClassImplementsProtocolClassMethods(aClass, aProtocol);
	implementsProtocol = implementsProtocol && DLCLClassImplementsProtocolInstanceMethods(aClass, aProtocol);
	return implementsProtocol;
}

@implementation DLConstraintLayout

@end
