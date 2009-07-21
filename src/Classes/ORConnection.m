//
//  Connection.m
//  
//
//  Created by Ryan Daigle on 7/30/08.
//  Copyright 2008 yFactorial, LLC. All rights reserved.
//

#import "ORConnection.h"
#import "ORResponse.h"
#import "NSData+Additions.h"
#import "NSMutableURLRequest+ResponseType.h"
#import "ORConnectionDelegate.h"
#import "ORConfigurationManager.h"
#import "OAuthConsumer/OAuthConsumer.h"
#import "NSMutableURLRequest+Parameters.h"


//#define debugLog(...) NSLog(__VA_ARGS__)
#ifndef debugLog(...)
	#define debugLog(...)
#endif

@implementation ORConnection

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

+ (ORResponse *)sendRequest:(NSMutableURLRequest *)request {
	
	//lots of servers fail to implement http basic authentication correctly, so we pass the credentials even if they are not asked for
	//TODO make this configurable?
	NSURL *url = [request URL];
	
	NSLog(@"%@", url);
	
	[self logRequest:request to:[url absoluteString]];
	
	ORConnectionDelegate *connectionDelegate = [[[ORConnectionDelegate alloc] init] autorelease];

	[[self activeDelegates] addObject:connectionDelegate];
	NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:request delegate:connectionDelegate startImmediately:NO] autorelease];
	connectionDelegate.connection = connection;

	[[UIApplication sharedApplication]	setNetworkActivityIndicatorVisible:YES];
	
	//use a custom runloop
	static NSString *runLoopMode = @"com.yfactorial.objectiveresource.connectionLoop";
	[connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:runLoopMode];
	[connection start];
	while (![connectionDelegate isDone]) {
		[[NSRunLoop currentRunLoop] runMode:runLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:.3]];
	}
	ORResponse *resp = [ORResponse responseFrom:(NSHTTPURLResponse *)connectionDelegate.response 
									   withBody:connectionDelegate.data 
									   andError:connectionDelegate.error];
	[resp log];
	
	[[UIApplication sharedApplication]	setNetworkActivityIndicatorVisible:NO];
	
	[activeDelegates removeObject:connectionDelegate];
	
	//if there are no more active delegates release the array
	if (0 == [activeDelegates count]) {
		NSMutableArray *tempDelegates = activeDelegates;
		activeDelegates = nil;
		[tempDelegates release];
	}
	
	return resp;
}

+ (ORResponse *)sendBy:(NSString *)method withBody:(NSData *)body to:(NSString *)path withParameters:(NSDictionary *)parameters {
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
		request = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:path]
												  consumer:[defaultManager consumer]
													 token:[defaultManager token]
													 realm:nil
										 signatureProvider:[defaultManager signatureProvider]];
		[request setHTTPMethod:method];
		if (parameters != nil) {
			NSMutableArray * oaParameters = [NSMutableArray array];
			OARequestParameter * parameter;
			for (id key in [parameters allKeys]) {
				parameter = [OARequestParameter requestParameterWithName:key 
																   value:[parameters valueForKey:key]];
				[oaParameters addObject:parameter]; 
			}
			[request setParameters:oaParameters];
		}
		[(OAMutableURLRequest *)request prepare];
		[request autorelease];
	} else if ([defaultManager authenticationMethod] == ORAuthenticationMethodNone) {
		request = [NSMutableURLRequest requestWithUrl:[NSURL URLWithString:path] 
											andMethod:method];
	}
	if ([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"]) {
		[request setHTTPBody:body];
		[request setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
        [request setValue:[NSString stringWithFormat:@"application/%@", @"xml"] forHTTPHeaderField:@"Content-Type"];
	}
	return [self sendRequest:request];
}

+ (ORResponse *)post:(NSData *)body to:(NSString *)url {
	return [self sendBy:@"POST" withBody:body to:url withParameters:nil];
}

+ (ORResponse *)put:(NSData *)body to:(NSString *)url {
	return [self sendBy:@"PUT" withBody:body to:url withParameters:nil];
}

+ (ORResponse *)get:(NSString *)url {
	return [self sendBy:@"GET" withBody:nil to:url withParameters:nil];
}

+ (ORResponse *)get:(NSString *)url withParameters:(NSDictionary *)parameters {
	return [self sendBy:@"GET" withBody:nil to:url withParameters:parameters];
}

+ (ORResponse *)delete:(NSString *)url {
	return [self sendBy:@"DELETE" withBody:nil to:url withParameters:nil];
}

+ (void) cancelAllActiveConnections {
	for (ORConnectionDelegate *delegate in activeDelegates) {
		[delegate performSelectorOnMainThread:@selector(cancel) withObject:nil waitUntilDone:NO];
	}
}

@end
