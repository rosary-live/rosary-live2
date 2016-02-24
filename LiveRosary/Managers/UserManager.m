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
#import <AFNetworking/AFNetworking.h>

NSString * const ErrorDomainUserManager = @"ErrorDomainUserManager";
NSInteger const ErrorCodeUserManager_Exception = 1;
NSString * const UserDefaultEmail = @"UserDefaultEmail";
NSString * const UserDefaultPassword = @"UserDefaultPassword";

NSString * const NotificationUserLoggedIn = @"NotificationUserLoggedIn";
NSString * const NotificationUserLoggedOut = @"NotificationUserLoggedOut";


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
        self.authClient = [LiveRosaryAuthenticationClient identityProviderWithAppname:@"LiveRosary"];

        //[AWSLogger defaultLogger].logLevel = AWSLogLevelVerbose;
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
        AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = self.configuration;
        [[self.credentialsProvider getIdentityId] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
            NSLog(@"%@", task.result);
            
            return [[self.configuration.credentialsProvider refresh] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationUserLoggedIn object:nil];
                
                if(completion) completion(nil);
                return [AWSTask taskWithResult:nil];
            }];
        }];
    }
//    else
//    {
//        AWSCognitoCredentialsProvider* credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
//                                                              initWithRegionType:AWSRegionUSEast1
//                                                              identityPoolId:@"us-east-1:e071f60e-332c-4883-a4f0-f8bc27c46173"];
//    
//        AWSServiceConfiguration* configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:credentialsProvider];
//    
//        [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
//    }
}

- (void)createUserWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSError* error))completion;
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString* postLength = [NSString stringWithFormat:@"%d", (int)postData.length];
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:[NSURL URLWithString:@"https://9wwr7dvesk.execute-api.us-east-1.amazonaws.com/prod/CreateUser"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"hhpm1l5N771l3eZf7V4Lk8AjWyYgZbPM7XPPU8Jw" forHTTPHeaderField:@"x-api-key"];
    [request setHTTPBody:postData];

    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"%@ %@", response, responseObject);
            
            NSNumber* created = (NSNumber*)responseObject[@"created"];
            if(created != nil && [created integerValue] == 1)
            {
                [self loginWithEmail:dictionary[@"email"] password:dictionary[@"password"] completion:completion];
            }
            else
            {
                safeBlock(completion, [NSError errorWithDomain:ErrorDomainUserManager code:-10 userInfo:nil]);
            }
        }
    }];
    [dataTask resume];
}

- (void)loginWithEmail:(NSString*)email password:(NSString*)password completion:(void (^)(NSError* error))completion
{
    [[self.authClient login:email password:password] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        self.email = email;
        self.password = password;
        
        [self initializeCognitoWithCompletion:completion];
        return [AWSTask taskWithResult:nil];
    }];
}

- (void)logoutWithCompletion:(void (^)(NSError* error))completion
{
    [self.authClient logout];
    [self.credentialsProvider clearCredentials];
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationUserLoggedOut object:nil];
    safeBlock(completion, nil);
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

- (void)refreshTokenWithCompletion:(void (^)(NSError* error))completion
{
    [[self.credentialsProvider.identityProvider refresh] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        NSLog(@"%@", task.result);
        
        return [[self.configuration.credentialsProvider refresh] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
            AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = self.configuration;
            
            if(completion) completion(nil);
            return [AWSTask taskWithResult:nil];
        }];
    }];
}

@end
