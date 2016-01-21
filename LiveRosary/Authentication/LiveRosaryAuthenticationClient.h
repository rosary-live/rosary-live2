//
//  LiveRosaryAuthenticationClient.h
//  LiveRosary
//
//  Created by richardtaylor on 1/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>

//FOUNDATION_EXPORT NSString *const LoginURI;
//FOUNDATION_EXPORT NSString *const GetTokenURI;
FOUNDATION_EXPORT NSString *const LiveRosaryAuthenticationClientDomain;
typedef NS_ENUM(NSInteger, DeveloperAuthenticationClientErrorType) {
    LiveRosaryAuthenticationClientInvalidConfig,
    LiveRosaryAuthenticationClientDecryptError,
    LiveRosaryAuthenticationClientLoginError,
    LiveRosaryAuthenticationClientUnknownError,
};

@class AWSTask;

@interface LiveRosaryAuthenticationResponse : NSObject

@property (nonatomic, strong, readonly) NSString* identityId;
//@property (nonatomic, strong, readonly) NSString* identityPoolId;
@property (nonatomic, strong, readonly) NSString* token;

@end

@interface LiveRosaryAuthenticationClient : NSObject

@property (nonatomic, strong) NSString* appname;
//@property (nonatomic, strong) NSString* endpoint;

+ (instancetype)identityProviderWithAppname:(NSString*)appname;// endpoint:(NSString*)endpoint;
- (instancetype)initWithAppname:(NSString*)appname;// endpoint:(NSString*)endpoint;

- (BOOL)isAuthenticated;
- (AWSTask*)getToken:identityId logins:(NSDictionary *)logins;
- (AWSTask*)login:(NSString *)email password:(NSString *)password;
- (void)logout;

@end
