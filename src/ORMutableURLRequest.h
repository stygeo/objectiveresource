//
//  ORMutableURLRequest.h
//  ObjectiveResource
//
//  Created by Ludovic Galabru on 16/07/09.
//  Copyright 2009 Silicon Frog. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ORMutableURLRequest : NSMutableURLRequest {
	NSMutableDictionary * parameters;
}

@property(nonatomic, retain) NSMutableDictionary * parameters;

@end
