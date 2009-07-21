//
//  ORConnection.h
//  
//
//  Created by Ryan Daigle on 7/30/08.
//  Copyright 2008 yFactorial, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORResponse;

@interface ORConnection : NSObject
+ (void) setTimeout:(float)timeout;
+ (float) timeout;

+ (ORResponse *)post:(NSData *)body to:(NSString *)url;
+ (ORResponse *)put:(NSData *)body to:(NSString *)url;
+ (ORResponse *)get:(NSString *)url;
+ (ORResponse *)get:(NSString *)url withParameters:(NSDictionary *)dictionary;
+ (ORResponse *)delete:(NSString *)url;

+ (void) cancelAllActiveConnections;

@end
