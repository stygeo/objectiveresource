//
//  NSMutableURLRequest+ResponseType.m
//  active_resource
//
//  Created by James Burka on 1/19/09.
//  Copyright 2009 Burkaprojects. All rights reserved.
//

#import "NSMutableURLRequest+ResponseType.h"
#import "ObjectiveResource.h"
#import "Connection.h"

@implementation NSMutableURLRequest(ResponseType)

+(NSMutableURLRequest *) requestWithUrl:(NSURL *)url andMethod:(NSString*)method {
	NSMutableURLRequest * request;
	request = [NSMutableURLRequest requestWithURL:url 
									  cachePolicy:NSURLRequestReloadIgnoringCacheData
								  timeoutInterval:[Connection timeout]];
	[request setHTTPMethod:method];
	return request;
}

@end
