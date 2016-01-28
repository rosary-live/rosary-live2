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
NSString * const UserDefaultEmail = @"UserDefaultEmail";
NSString * const UserDefaultPassword = @"UserDefaultPassword";

@interface UserManager()
@property (nonatomic, strong) AWSCognitoCredentialsProvider* credentialsProvider;
@property (nonatomic, strong) LiveRosaryAuthenticationClient* authClient;
@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* password;
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
        [self initializeCognitoWithCompletion:^(NSError *error) {
        }];
    }
    return self;
}

- (void)setEmail:(NSString *)email
{
    [[NSUserDefaults standardUserDefaults] setObject:email forKey:UserDefaultEmail];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*)email
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:UserDefaultEmail];
}

- (void)setPassword:(NSString *)password
{
    [[NSUserDefaults standardUserDefaults] setObject:password forKey:UserDefaultPassword];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*)password
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:UserDefaultPassword];
}

- (BOOL)isLoggedIn
{
    return self.email != nil;
}

- (void)initializeCognitoWithCompletion:(void (^)(NSError* error))completion
{
    if(self.isLoggedIn)
    {
        NSDictionary* logins = @{ @"login.liverosary": self.email };
        id<AWSCognitoIdentityProvider> identityProvider = [[LiveRosaryAuthenticatedIdentityProvider alloc] initWithRegionType:AWSRegionUSEast1
                                                                                                                   identityId:self.authClient.identityId
                                                                                                               identityPoolId:@"us-east-1:e071f60e-332c-4883-a4f0-f8bc27c46173"
                                                                                                                       logins:logins
                                                                                                                 providerName:@"login.liverosary"
                                                                                                                   authClient:self.authClient];
        
        self.credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:AWSRegionUSEast1
                                                                            identityProvider:identityProvider
                                                                               unauthRoleArn:nil
                                                                                 authRoleArn:nil];
        
        self.configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1
                                                         credentialsProvider:self.credentialsProvider];
        [[self.credentialsProvider getIdentityId] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
            NSLog(@"%@", task.result);
            
            return [[self.configuration.credentialsProvider refresh] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
                AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = self.configuration;
                
                if(completion) completion(nil);
                return [AWSTask taskWithResult:nil];
            }];
        }];
    }
    else
    {
        AWSCognitoCredentialsProvider* credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                                                              initWithRegionType:AWSRegionUSEast1
                                                              identityPoolId:@"us-east-1:e071f60e-332c-4883-a4f0-f8bc27c46173"];
    
        AWSServiceConfiguration* configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:credentialsProvider];
    
        [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    }
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
        self.email = email;
        self.password = password;
        
        [self initializeCognitoWithCompletion:completion];
        return [AWSTask taskWithResult:nil];
    }];
}

- (BOOL)credentialsExpired
{
    return self.credentialsProvider.expiration == nil || [[NSDate date] compare:self.credentialsProvider.expiration] == NSOrderedAscending;
}

- (void)refreshCredentialsWithCompletion:(void (^)(NSError* error))completion
{
    [[self.configuration.credentialsProvider refresh] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = self.configuration;
        
        if(completion) completion(nil);
        return [AWSTask taskWithResult:nil];
    }];
}

- (void)updateUserInfoWithDictionary:(NSDictionary*)info
{
}

@end
