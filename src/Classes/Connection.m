//
//  Connection.m
//  
//
//  Created by Ryan Daigle on 7/30/08.
//  Copyright 2008 yFactorial, LLC. All rights reserved.
//

#import "Connection.h"
#import "Response.h"
#import "NSData+Additions.h"
#import "NSMutableURLRequest+ResponseType.h"
#import "ConnectionDelegate.h"
#import "ORConfigurationManager.h"
#import "OAuthConsumer/OAuthConsumer.h"


//#define debugLog(...) NSLog(__VA_ARGS__)
#ifndef debugLog(...)
	#define debugLog(...)
#endif

@implementation Connection

static float timeoutInterval = 5.0;

static NSMutableArray *activeDelegates;

+ (NSMutableArray *)activeDelegates {
	if (nil == activeDelegates) {
		activeDelegates = [NSMutableArray array];
		[activeDelegates retain];
	}
	return activeDelegates;
}

+ (void)setTimeout:(float)timeOut {
	timeoutInterval = timeOut;
}
+ (float)timeout {
	return timeoutInterval;
}

+ (void)logRequest:(NSURLRequest *)request to:(NSString *)url {
	debugLog(@"%@ -> %@", [request HTTPMethod], url);
	if([request HTTPBody]) {
		debugLog([[[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding] autorelease]);
	}
}

+ (Response *)sendRequest:(NSMutableURLRequest *)request {
	
	//lots of servers fail to implement http basic authentication correctly, so we pass the credentials even if they are not asked for
	//TODO make this configurable?
	NSURL *url = [request URL];

	[self logRequest:request to:[url absoluteString]];
	
	ConnectionDelegate *connectionDelegate = [[[ConnectionDelegate alloc] init] autorelease];

	[[self activeDelegates] addObject:connectionDelegate];
	NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:request delegate:connectionDelegate startImmediately:NO] autorelease];
	connectionDelegate.connection = connection;

	
	//use a custom runloop
	static NSString *runLoopMode = @"com.yfactorial.objectiveresource.connectionLoop";
	[connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:runLoopMode];
	[connection start];
	while (![connectionDelegate isDone]) {
		[[NSRunLoop currentRunLoop] runMode:runLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:.3]];
	}
	Response *resp = [Response responseFrom:(NSHTTPURLResponse *)connectionDelegate.response 
								   withBody:connectionDelegate.data 
								   andError:connectionDelegate.error];
	[resp log];
	
	[activeDelegates removeObject:connectionDelegate];
	
	//if there are no more active delegates release the array
	if (0 == [activeDelegates count]) {
		NSMutableArray *tempDelegates = activeDelegates;
		activeDelegates = nil;
		[tempDelegates release];
	}
	
	return resp;
}

+ (Response *)sendBy:(NSString *)method withBody:(NSString *)body to:(NSString *)path {
	NSMutableURLRequest * request;
	NSURL * url;
	ORConfigurationManager * defaultManager;
	
	url = [NSURL URLWithString:path];
	defaultManager = [ORConfigurationManager defaultManager];
		
	if ([defaultManager authenticationMethod] == ORAuthenticationMethodHTTPBasic) {
		NSString * user = [defaultManager remoteUser];
		NSString * password = [defaultManager remotePassword];
		NSString *authString = [[[NSString stringWithFormat:@"%@:%@",user, password] dataUsingEncoding:NSUTF8StringEncoding] base64Encoding];
		[request addValue:[NSString stringWithFormat:@"Basic %@", authString] forHTTPHeaderField:@"Authorization"]; 
		NSString *escapedUser = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, 
																					(CFStringRef)user, NULL, (CFStringRef)@"@.:", kCFStringEncodingUTF8);
		NSString *escapedPassword = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, 
																						(CFStringRef)password, NULL, (CFStringRef)@"@.:", kCFStringEncodingUTF8);
		NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@://%@:%@@%@",[url scheme],escapedUser,escapedPassword,[url host],nil];
		if([url port]) {
			[urlString appendFormat:@":%@",[url port],nil];
		}
		[urlString appendString:[url path]];
		if([url query]){
			[urlString appendFormat:@"?%@",[url query],nil];
		}
		
		request = [NSMutableURLRequest requestWithUrl:[NSURL URLWithString:urlString] 
											andMethod:method];
		[escapedUser release];
		[escapedPassword release];
		
	} else if ([defaultManager authenticationMethod] == ORAuthenticationMethodOAuth) {
		OARequestParameter * nameParam;
		NSArray * query = [[url query] componentsSeparatedByString:@"&"];
		NSMutableArray * parameters = [[[NSMutableArray alloc] init] autorelease];
		NSURL * cleanURL = [[NSURL alloc] initWithScheme:[url scheme] 
											   host:[url host] 
											   path:[url path]];
		
		for (id parameter in query) {
			NSArray * components = [parameter componentsSeparatedByString:@"="];
			nameParam = [[OARequestParameter alloc] initWithName:[components objectAtIndex:0]
														   value:[components objectAtIndex:1]];
			[parameters addObject:nameParam];
			[nameParam release];
		}
		
		request = [[OAMutableURLRequest alloc] initWithURL:cleanURL
												  consumer:[defaultManager consumer]
													 token:[defaultManager token]
													 realm:nil
										 signatureProvider:[defaultManager signatureProvider]];
		[request setHTTPMethod:method];
		[request setParameters:parameters];
		[(OAMutableURLRequest *)request prepare];
		[request autorelease];
		[cleanURL release];
	} else if ([defaultManager authenticationMethod] == ORAuthenticationMethodNone) {
		request = [NSMutableURLRequest requestWithUrl:[NSURL URLWithString:path] 
											andMethod:method];
	}

	[request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
	return [self sendRequest:request];
}

+ (Response *)post:(NSString *)body to:(NSString *)url {
	return [self sendBy:@"POST" withBody:body to:url];
}

+ (Response *)put:(NSString *)body to:(NSString *)url {
	return [self sendBy:@"PUT" withBody:body to:url];
}

+ (Response *)get:(NSString *)url {
	return [self sendBy:@"GET" withBody:nil to:url];
}

+ (Response *)delete:(NSString *)url {
	return [self sendBy:@"DELETE" withBody:nil to:url];
}

+ (void) cancelAllActiveConnections {
	for (ConnectionDelegate *delegate in activeDelegates) {
		[delegate performSelectorOnMainThread:@selector(cancel) withObject:nil waitUntilDone:NO];
	}
}

@end
