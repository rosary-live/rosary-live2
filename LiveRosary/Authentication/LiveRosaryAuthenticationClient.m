//
//  LiveRosaryAuthenticationClient.m
//  LiveRosary
//
//  Created by richardtaylor on 1/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LiveRosaryAuthenticationClient.h"
#import <AWSCore/AWSCore.h>
#import <AWSLambda/AWSLambda.h>
#import <UICKeyChainStore/UICKeyChainStore.h>
#import <AFNetworking/AFNetworking.h>

NSString *const LiveRosaryAuthenticationClientDomain = @"LiveRosaryAuthenticationClientDomain";

NSString * const KeyEmail = @"KeyEmail";
NSString * const KeyPassword = @"KeyPassword";
NSString * const KeyIdentityId = @"KeyIdentityId";
NSString * const KeyToken = @"KeyToken";

@interface LiveRosaryAuthenticationResponse()

@property (nonatomic, strong) NSString* identityId;
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSDictionary* user;

@end

@implementation LiveRosaryAuthenticationResponse
@end

@interface LiveRosaryAuthenticationClient()
@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* password;
@property (nonatomic, strong) UICKeyChainStore* keychain;

@end

@implementation LiveRosaryAuthenticationClient


+ (instancetype)identityProviderWithAppname:(NSString *)appname {
    return [[LiveRosaryAuthenticationClient alloc] initWithAppname:appname];
}

- (instancetype)initWithAppname:(NSString *)appname {
    if (self = [super init]) {
        self.appname  = appname;
        
        self.keychain = _keychain = [UICKeyChainStore keyChainStoreWithService:[NSString stringWithFormat:@"%@.%@.%@", [NSBundle mainBundle].bundleIdentifier, [LiveRosaryAuthenticationClient class], self.appname]];

        self.email = self.keychain[KeyEmail];
        self.password = self.keychain[KeyPassword];
        self.identityId = self.keychain[KeyIdentityId];
        self.token = self.keychain[KeyToken];
    }
    
    return self;
}

- (BOOL)isAuthenticated {
    return self.identityId != nil;
}

- (AWSTask *)login:(NSString*)email password:(NSString*)password {
    return [[AWSTask taskWithResult:nil] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        NSString* post =[NSString stringWithFormat:@"{\"email\":\"%@\",\"password\":\"%@\"}", email, password];
        NSData* postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        NSString* postLength = [NSString stringWithFormat:@"%d", (int)postData.length];
        
        NSMutableURLRequest *request = [NSMutableURLRequest new];
        [request setURL:[NSURL URLWithString:@"https://9wwr7dvesk.execute-api.us-east-1.amazonaws.com/prod/Login"]];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"hhpm1l5N771l3eZf7V4Lk8AjWyYgZbPM7XPPU8Jw" forHTTPHeaderField:@"x-api-key"];
        [request setHTTPBody:postData];
        
        NSError *error;
        NSURLResponse *response;
        NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if(error == nil)
        {
            NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
            if(error == nil)
            {
                NSLog(@"Response: %@", responseDict);
                
                NSNumber* login = responseDict[@"login"];
                if(login != nil && [login boolValue])
                {
                    self.keychain[KeyEmail] = self.email = email;
                    self.keychain[KeyPassword] = self.password = password;
                    self.keychain[KeyIdentityId] = self.identityId = responseDict[@"identityId"];
                    self.keychain[KeyToken] = self.token = responseDict[@"token"];
                    
                    LiveRosaryAuthenticationResponse* authResponse;
                    authResponse = [LiveRosaryAuthenticationResponse new];
                    authResponse.identityId = self.identityId;
                    authResponse.token = self.token;
                    authResponse.user = responseDict[@"user"];
                    
                    return [AWSTask taskWithResult:authResponse];
                }
                else
                {
                    return [AWSTask taskWithError:[NSError errorWithDomain:LiveRosaryAuthenticationClientDomain code:-1 userInfo:nil]];
                }
            }
            else
            {
                return [AWSTask taskWithError:error];
            }
        }
        else
        {
            return [AWSTask taskWithError:error];
        }
    }];
}

- (void)logout {
    self.keychain[KeyEmail] = self.email = nil;
    self.keychain[KeyPassword] = self.password = nil;
    self.keychain[KeyIdentityId] = self.identityId = nil;
    self.keychain[KeyToken] = self.token = nil;
}

- (AWSTask *)getToken
{
    if (![self isAuthenticated]) {
        return [AWSTask taskWithError:[NSError errorWithDomain:LiveRosaryAuthenticationClientDomain
                                                          code:LiveRosaryAuthenticationClientLoginError
                                                      userInfo:nil]];
    }
    
    return [self login:self.email password:self.password];
}

- (void)updatePassword:(NSString*)password
{
    self.keychain[KeyPassword] = self.password = password;

}

@end
