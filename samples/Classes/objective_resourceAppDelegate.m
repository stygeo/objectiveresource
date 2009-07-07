//
//  active_resourceAppDelegate.m
//  active_resource
//
//  Created by vickeryj on 8/21/08.
//  Copyright Joshua Vickery 2008. All rights reserved.
//

#import "objective_resourceAppDelegate.h"
#import "ObjectiveResource/ObjectiveResource.h"

@implementation objective_resourceAppDelegate

@synthesize window, navigationController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {	
	
	//Configure ObjectiveResource
	[[ORConfigurationManager defaultManager] setRemoteSite:@"http://localhost:3000/"];
	
	// dogs is password protected
	[[ORConfigurationManager defaultManager] setRemoteUser:@"Hiro"];
	[[ORConfigurationManager defaultManager] setRemotePassword:@"Protagonist"];
	// use json
	//[ObjectiveResourceConfig setResponseType:JSONResponse];
	
	// use xml
	[[ORConfigurationManager defaultManager]  setRemoteResponseType:XmlResponse];
	[window addSubview:navigationController.view];
	
	// Override point for customization after app launch	
    [window makeKeyAndVisible];
}


- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}


@end
