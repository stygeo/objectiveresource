//
//  ORConfigurationManager.m
//  ObjectiveResource
//
//  Created by Ludovic Galabru on 26/06/09.
//  Copyright 2009 Silicon Frog. All rights reserved.
//

#import "ObjectiveResource.h"

// Response Formats
typedef enum {
	XmlResponse = 0,
	JSONResponse,
} ORSResponseFormat;

typedef enum {
	ORAuthenticationMethodNone,
	ORAuthenticationMethodHTTPBasic,
	ORAuthenticationMethodOAuth
} ORAuthenticationMethod;


@class OAToken;
@class OAConsumer;
@protocol OASignatureProviding;

@interface ORConfigurationManager : NSObject {
	NSString * _remoteSite;
	NSString * _remoteProtocolExtension;
	NSString * _localPrefix;
	SEL _remoteParseDataMethod;
	SEL _remoteSerializeMethod;
	ORSResponseFormat _remoteResponseType;
	ORAuthenticationMethod _authenticationMethod;
	
	//HTTP Basic Authentication
	NSString * _remoteUser;
	NSString * _remotePassword;
	
	//OAuth
	OAToken * _token;
	OAConsumer * _consumer;
	id <OASignatureProviding, NSObject> _signatureProvider;
}

+ (ORConfigurationManager *)defaultManager;

@property(nonatomic, copy) NSString * remoteSite;
@property(nonatomic, copy) NSString * remoteProtocolExtension;
@property(nonatomic, copy) NSString * localPrefix;
@property(nonatomic, assign) SEL remoteParseDataMethod;
@property(nonatomic, assign) SEL remoteSerializeMethod;
@property(nonatomic, assign) ORSResponseFormat remoteResponseType;
@property(nonatomic, assign) ORAuthenticationMethod authenticationMethod;

@property(nonatomic, copy) NSString * remoteUser;
@property(nonatomic, copy) NSString * remotePassword;

@property(nonatomic, copy) OAToken * token;
@property(nonatomic, copy) OAConsumer * consumer;
@property(nonatomic, retain) id <OASignatureProviding, NSObject> signatureProvider;


@end
