//
//  UserManager.m
//  LiveRosary
//
//  Created by richardtaylor on 1/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "UserManager.h"
#import <AWSCore/AWSCore.h>
#import <AWSCognito/AWSCognito.h>
#import <AWSLambda/AWSLambda.h>
#import "LiveRosaryAuthenticatedIdentityProvider.h"
#import "LiveRosaryAuthenticationClient.h"

NSString * const ErrorDomainUserManager = @"ErrorDomainUserManager";
NSInteger const ErrorCodeUserManager_Exception = 1;

@interface UserManager()
@property (nonatomic, strong) AWSCognitoCredentialsProvider* credentialsProvider;
@property (nonatomic, strong) LiveRosaryAuthenticationClient* authClient;
@end

@implementation UserManager

+ (instancetype)sharedManager
{
    static UserManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if(self = [super init])
    {
        [AWSLogger defaultLogger].logLevel = AWSLogLevelVerbose;
        [self initializeCognito];
    }
    return self;
}

- (BOOL)isLoggedIn
{
    return NO;
}

- (void)initializeCognito
{
    AWSCognitoCredentialsProvider* credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                                                          initWithRegionType:AWSRegionUSEast1
                                                          identityPoolId:@"us-east-1:e071f60e-332c-4883-a4f0-f8bc27c46173"];
    
    AWSServiceConfiguration* configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:credentialsProvider];
    
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
}

- (void)createUserWithEmail:(NSString*)email password:(NSString*)password completion:(void (^)(NSError* error))completion
{
    AWSLambdaInvoker* lambdaInvoker = [AWSLambdaInvoker defaultLambdaInvoker];
    
    [[lambdaInvoker invokeFunction:@"LambdAuthCreateUser" JSONObject:@{ @"email": email, @"password": password }] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {

        if(task.error)
        {
            DDLogError(@"createUser: error %@", task.error);
            safeBlock(completion, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"createUser exception: %@", task.exception);
            safeBlock(completion, [NSError errorWithDomain:ErrorDomainUserManager code:ErrorCodeUserManager_Exception userInfo:nil]);
        }
        else if(task.result) {
            DDLogDebug(@"createUser result: %@", task.result);
            safeBlock(completion, nil);
        }
        
        return nil;
    }];
}

- (void)loginWithEmail:(NSString*)email password:(NSString*)password completion:(void (^)(NSError* error))completion
{
    self.authClient = [LiveRosaryAuthenticationClient identityProviderWithAppname:@"LiveRosary"];
    
    [[self.authClient login:email password:password] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        NSDictionary* logins = @{ @"login.liverosary": email };
        id<AWSCognitoIdentityProvider> identityProvider = [[LiveRosaryAuthenticatedIdentityProvider alloc] initWithRegionType:AWSRegionUSEast1
                                                                                                                   identityId:nil
                                                                                                               identityPoolId:@"us-east-1:e071f60e-332c-4883-a4f0-f8bc27c46173"
                                                                                                                       logins:logins
                                                                                                                 providerName:@"login.liverosary"
                                                                                                                   authClient:self.authClient];
        
        self.credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:AWSRegionUSEast1
                                                                            identityProvider:identityProvider
                                                                               unauthRoleArn:nil
                                                                                 authRoleArn:nil];
        
        AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1
                                                                             credentialsProvider:self.credentialsProvider];
        AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
        return[[self.credentialsProvider getIdentityId] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
            NSLog(@"%@", task.result);
            
            return [AWSTask taskWithResult:nil];
        }];
    }];
}

- (void)updateUserInfoWithDictionary:(NSDictionary*)info
{
}

@end
