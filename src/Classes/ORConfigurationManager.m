//
//  ORConfigurationManager.m
//  ObjectiveResource
//
//  Created by Ludovic Galabru on 26/06/09.
//  Copyright 2009 Silicon Frog. All rights reserved.
//

#import "ORConfigurationManager.h"


@implementation ORConfigurationManager

@synthesize remoteSite = _remoteSite;
@synthesize remoteProtocolExtension = _remoteProtocolExtension;
@synthesize localPrefix = _localPrefix;
@synthesize remoteResponseType = _remoteResponseType;
@synthesize remoteParseDataMethod = _remoteParseDataMethod;
@synthesize remoteSerializeMethod = _remoteSerializeMethod;
@synthesize authenticationMethod = _authenticationMethod;

@synthesize remoteUser = _remoteUser;
@synthesize remotePassword = _remotePassword;

@synthesize token = _token;
@synthesize consumer = _consumer;
@synthesize signatureProvider = _signatureProvider;

- (id)init {
	self = [super init];
	if (self != nil) {
		_remoteSite = nil;
		_remoteUser = nil;
		_remotePassword = nil;
		_localPrefix = nil;
		_remoteProtocolExtension = @".xml";
		_remoteParseDataMethod = @selector(fromXMLData:);
		_remoteSerializeMethod = @selector(toXMLElementExcluding:);
	}
	return self;
}

+ (ORConfigurationManager *)defaultManager {
	static ORConfigurationManager * defaultManager = nil;
	if (defaultManager == nil) {
		defaultManager = [[ORConfigurationManager alloc] init];
	}
	return defaultManager;
}

- (void)setRemoteResponseType:(ORSResponseFormat) format {
	_localPrefix = _localPrefix;
	switch (format) {
		case JSONResponse:
			[self setRemoteProtocolExtension:@".json"];
			[self setRemoteParseDataMethod:@selector(fromJSONData:)];
			[self setRemoteSerializeMethod:@selector(toJSONExcluding:)];
			break;
		default:
			[self setRemoteProtocolExtension:@".xml"];
			[self setRemoteParseDataMethod:@selector(fromXMLData:)];
			[self setRemoteSerializeMethod:@selector(toXMLElementExcluding:)];
			break;
	}
}


- (void)dealloc {
	[_remoteSite release];
	[_localPrefix release];
	[_remoteProtocolExtension release];
	
	[_remoteUser release];
	[_remotePassword release];
	
	[_token release];
	[_consumer release];
	[_signatureProvider release];
	[super dealloc];
}

@end
