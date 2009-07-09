//
//  ORConnectionManager.h
//
//  Created by Adam Alexander on 2/28/09.
//  Copyright 2009 yFactorial, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ORConnectionManager : NSObject {
	NSOperationQueue *operationQueue;
}
@property (nonatomic, retain) NSOperationQueue *operationQueue;
+ (ORConnectionManager *)sharedInstance;
- (void)cancelAllJobs;
- (void)runJob:(SEL)selector onTarget:(id)target;
- (void)runJob:(SEL)selector onTarget:(id)target withArgument:(id)argument;
@end
