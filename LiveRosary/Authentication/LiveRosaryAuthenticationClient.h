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

@property (nonatomic, readonly) BOOL success;
@property (nonatomic, strong, readonly) NSString* identityId;
@property (nonatomic, strong, readonly) NSString* token;
@property (nonatomic, strong, readonly) NSDictionary* user;

@end

@interface LiveRosaryAuthenticationClient : NSObject

@property (nonatomic, strong) NSString* appname;
@property (nonatomic, strong) NSString* identityId;
@property (nonatomic, strong) NSString* token;

+ (instancetype)identityProviderWithAppname:(NSString*)appname;
- (instancetype)initWithAppname:(NSString*)appname;

- (BOOL)isAuthenticated;
- (AWSTask*)getToken;
- (AWSTask*)login:(NSString *)email password:(NSString *)password;
- (void)logout;
- (void)updatePassword:(NSString*)password;

@end
