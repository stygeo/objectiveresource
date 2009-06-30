//
//  Connection.h
//  
//
//  Created by Ryan Daigle on 7/30/08.
//  Copyright 2008 yFactorial, LLC. All rights reserved.
//

@class Response;

@interface Connection : NSObject
+ (void) setTimeout:(float)timeout;
+ (float) timeout;

+ (Response *)post:(NSString *)body to:(NSString *)url;
+ (Response *)put:(NSString *)body to:(NSString *)url;
+ (Response *)get:(NSString *)url;
+ (Response *)delete:(NSString *)url;

+ (void) cancelAllActiveConnections;

@end
