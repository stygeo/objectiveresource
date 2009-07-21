//
//  NSObject+ObjectiveResource.m
//  objectivesync
//
//  Created by vickeryj on 1/29/09.
//  Copyright 2009 Joshua Vickery. All rights reserved.
//

#import "NSObject+ObjectiveResource.h"
#import "ORConnection.h"
#import "ORResponse.h"
#import "CoreSupport.h"
#import "XMLSerializableSupport.h"
#import "JSONSerializableSupport.h"
#import "ORConfigurationManager.h"

@implementation NSObject (ObjectiveResource)

// Find all items 
+ (NSArray *)findAllRemoteWithResponse:(NSError **)aError {
	ORResponse *res = [ORConnection get:[self getRemoteCollectionPath]];
	if([res isError] && aError) {
		*aError = res.error;
	}
	return [self performSelector:[[ORConfigurationManager defaultManager] remoteParseDataMethod] 
					  withObject:res.body];
}

+ (NSArray *)findAllRemote {
	NSError *aError;
	return [self findAllRemoteWithResponse:&aError];
}

+ (id)findRemote:(NSString *)elementId withResponse:(NSError **)aError {
	ORResponse *res = [ORConnection get:[self getRemoteElementPath:elementId]];
	if([res isError] && aError) {
		*aError = res.error;
	}
	return [self performSelector:[[ORConfigurationManager defaultManager] remoteParseDataMethod] 
					  withObject:res.body];
}

+ (id)findRemote:(NSString *)elementId {
	NSError *aError;
	return [self findRemote:elementId withResponse:&aError];
}

+ (NSString *)getRemoteElementName {
	NSString * remoteElementName = NSStringFromClass([self class]);
	NSString * prefix = [[ORConfigurationManager defaultManager] localPrefix];
	if (prefix != nil) {
		remoteElementName = [remoteElementName substringFromIndex:[prefix length]];
	}
	return [[remoteElementName stringByReplacingCharactersInRange:NSMakeRange(0, 1) 
													   withString:[[remoteElementName substringWithRange:NSMakeRange(0, 1)] 
																   lowercaseString]] 
			underscore];
}

+ (NSString *)getRemoteCollectionName {
	return [[self getRemoteElementName] stringByAppendingString:@"s"];
}

+ (NSString *)getRemoteElementPath:(NSString *)elementId {
	return [NSString stringWithFormat:@"%@%@/%@%@", [[ORConfigurationManager defaultManager] remoteSite], [self getRemoteCollectionName], elementId, [[ORConfigurationManager defaultManager] remoteProtocolExtension]];
}

+ (NSString *)getRemoteCollectionPath {
	return [[[[ORConfigurationManager defaultManager] remoteSite] stringByAppendingString:[self getRemoteCollectionName]] stringByAppendingString:[[ORConfigurationManager defaultManager] remoteProtocolExtension]];
}

+ (NSString *)getRemoteCollectionPathWithParameters:(NSDictionary *)parameters {
	return [self populateRemotePath:[self getRemoteCollectionPath] withParameters:parameters];
}	

+ (NSString *)populateRemotePath:(NSString *)path withParameters:(NSDictionary *)parameters {
	
	// Translate each key to have a preceeding ":" for proper URL param notiation
	NSMutableDictionary *parameterized = [NSMutableDictionary dictionaryWithCapacity:[parameters count]];
	for (NSString *key in parameters) {
		[parameterized setObject:[parameters objectForKey:key] forKey:[NSString stringWithFormat:@":%@", key]];
	}
	return [path gsub:parameterized];
}

- (NSString *)getRemoteCollectionPath {
	return [[self class] getRemoteCollectionPath];
}

// Converts the object to the data format expected by the server
- (NSString *)convertToRemoteExpectedType {	  
  return [self performSelector:[[ORConfigurationManager defaultManager] remoteSerializeMethod] 
					withObject:[self excludedPropertyNames]];
}


#pragma mark default equals methods for id and class based equality
- (BOOL)isEqualToRemote:(id)anObject {
	return 	[NSStringFromClass([self class]) isEqualToString:NSStringFromClass([anObject class])] &&
	[anObject respondsToSelector:@selector(getRemoteId)] && [[anObject getRemoteId]isEqualToString:[self getRemoteId]];
}
- (NSUInteger)hashForRemote {
	return [[self getRemoteId] intValue] + [NSStringFromClass([self class]) hash];
}

#pragma mark Instance-specific methods
- (id)getRemoteId {
	id result = nil;
	SEL idMethodSelector = NSSelectorFromString([self getRemoteClassIdName]);
	if ([self respondsToSelector:idMethodSelector]) {
		result = [self performSelector:idMethodSelector];
		if ([result respondsToSelector:@selector(stringValue)]) {
			result = [result stringValue];
		}
	}
	return result;
}
- (void)setRemoteId:(id)orsId {
	SEL setter = NSSelectorFromString([NSString stringWithFormat:@"set%@Id:",[self className]]);
	if ([self respondsToSelector:setter]) {
		[self performSelector:setter withObject:orsId];
	}
}


- (NSString *)getRemoteClassIdName {
	NSString * remoteElementName = NSStringFromClass([self class]);
	NSString * prefix = [[ORConfigurationManager defaultManager] localPrefix];
	if (prefix != nil) {
		remoteElementName = [remoteElementName substringFromIndex:[prefix length]];
	}
	return [NSString stringWithFormat:@"%@Id", 
			[remoteElementName stringByReplacingCharactersInRange:NSMakeRange(0, 1) 
													   withString:[[remoteElementName substringWithRange:NSMakeRange(0,1)] lowercaseString]]];
}

- (BOOL)createRemoteAtPath:(NSString *)path withResponse:(NSError **)aError {
	ORResponse *res = [ORConnection post:[[self convertToRemoteExpectedType] dataUsingEncoding:NSUTF8StringEncoding] 
									  to:path];
	if([res isError] && aError) {
		*aError = res.error;
	}
	if ([res isSuccess]) {
		NSDictionary *newProperties = [[[self class] performSelector:[[ORConfigurationManager defaultManager] remoteParseDataMethod] 
														  withObject:res.body] 
									   properties];
		[self setProperties:newProperties];
		return YES;
	}
	else {
		return NO;
	}
}

-(BOOL)updateRemoteAtPath:(NSString *)path withResponse:(NSError **)aError {	
	ORResponse *res = [ORConnection put:[[self convertToRemoteExpectedType] dataUsingEncoding:NSUTF8StringEncoding] 
									 to:path];
	if([res isError] && aError) {
		*aError = res.error;
	}
	if ([res isSuccess]) {
		if([(NSString *)[res.headers objectForKey:@"Content-Length"] intValue] > 1) {
			NSDictionary *newProperties = [[[self class] performSelector:[[ORConfigurationManager defaultManager] remoteParseDataMethod] withObject:res.body] properties];
			[self setProperties:newProperties];
		}
		return YES;
	}
	else {
		return NO;
	}
}

- (BOOL)destroyRemoteAtPath:(NSString *)path withResponse:(NSError **)aError {
	ORResponse *res = [ORConnection delete:path];
	if([res isError] && aError) {
		*aError = res.error;
	}
	return [res	isSuccess];
}

- (BOOL)createRemoteWithResponse:(NSError **)aError {
	return [self createRemoteAtPath:[self getRemoteCollectionPath] withResponse:aError];	
}

- (BOOL)createRemote {
	NSError *error;
	return [self createRemoteWithResponse:&error];
}

- (BOOL)createRemoteWithParameters:(NSDictionary *)parameters andResponse:(NSError **)aError {
	return [self createRemoteAtPath:[[self class] getRemoteCollectionPathWithParameters:parameters] withResponse:aError];
}

- (BOOL)createRemoteWithParameters:(NSDictionary *)parameters {
	NSError *error;
	return [self createRemoteWithParameters:parameters andResponse:&error];
}


- (BOOL)destroyRemoteWithResponse:(NSError **)aError {
	id myId = [self getRemoteId];
	if (nil != myId) {
		return [self destroyRemoteAtPath:[[self class] getRemoteElementPath:myId] withResponse:aError];
	}
	else {
		// this should return a error
		return NO;
	}
}

- (BOOL)destroyRemote {
	NSError *error;
	return [self destroyRemoteWithResponse:&error];
}

- (BOOL)updateRemoteWithResponse:(NSError **)aError {
	id myId = [self getRemoteId];
	if (nil != myId) {
		return [self updateRemoteAtPath:[[self class] getRemoteElementPath:myId] withResponse:aError];
	}
	else {
		// this should return an error
		return NO;
	}
}

- (BOOL)updateRemote {
	NSError *error;
	return [self updateRemoteWithResponse:&error];
}

- (BOOL)saveRemoteWithResponse:(NSError **)aError {
	id myId = [self getRemoteId];
	if (nil == myId) {
		return [self createRemoteWithResponse:aError];
	}
	else {
		return [self updateRemoteWithResponse:aError];
	}
}

- (BOOL)saveRemote {
	NSError *error;
	return [self saveRemoteWithResponse:&error];
}

/*
 Override this in your model class to extend or replace the excluded properties
 eg.
 - (NSArray *)excludedPropertyNames
 {
  NSArray *exclusions = [NSArray arrayWithObjects:@"extraPropertyToExclude", nil];
  return [[super excludedPropertyNames] arrayByAddingObjectsFromArray:exclusions];
 }
*/

- (NSArray *)excludedPropertyNames
{
  // exclude id , created_at , updated_at
  return [NSArray arrayWithObjects:[self getRemoteClassIdName],@"createdAt",@"updatedAt",nil]; 
}


@end
