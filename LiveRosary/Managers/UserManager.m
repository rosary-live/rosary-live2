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
#import <AWSS3/AWSS3.h>

NSString * const ErrorDomainUserManager = @"ErrorDomainUserManager";
NSInteger const ErrorCodeUserManager_Exception = 1;
NSString * const UserDefaultEmail = @"UserDefaultEmail";
NSString * const UserDefaultPassword = @"UserDefaultPassword";

NSString * const NotificationUserLoggedIn = @"NotificationUserLoggedIn";
NSString * const NotificationUserLoggedOut = @"NotificationUserLoggedOut";

NSString* const ApiKey = @"hhpm1l5N771l3eZf7V4Lk8AjWyYgZbPM7XPPU8Jw";

@interface UserManager() <AFURLResponseSerialization>
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
        [self populateLanguages];
        self.authClient = [LiveRosaryAuthenticationClient identityProviderWithAppname:@"LiveRosary"];

        //[AWSLogger defaultLogger].logLevel = AWSLogLevelVerbose;
        [self initializeCognitoWithCompletion:^(NSError *error) {
        }];
    }
    return self;
}

- (void)populateLanguages
{
    NSMutableArray<NSString*>* languages = [NSMutableArray new];
    for(NSString* code in [NSLocale ISOLanguageCodes])
    {
        if(code != nil)
        {
            NSString* name = [[[NSLocale alloc] initWithLocaleIdentifier:code] displayNameForKey:NSLocaleIdentifier value:code];
            if(name != nil)
            {
                [languages addObject:name];
            }
        }
    }
    
    _languages = [NSArray arrayWithArray:languages];
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
                
                self.currentUser = [[UserModel alloc] initWithDict:((LiveRosaryAuthenticatedIdentityProvider*)identityProvider).user];
                [self loadAvatarImage];
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

- (void)createUserWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSError* error))completion
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
    [request setValue:ApiKey forHTTPHeaderField:@"x-api-key"];
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

- (NSString*)avatarImagePath
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"avatar.jpg"];
}

- (NSString*)serverAvatarImageFilename
{
    return [self.email stringByReplacingOccurrencesOfString:@"@" withString:@"-"];
}

- (void)uploadAvatarImage:(UIImage*)image completion:(void (^)(NSError* error))completion
{
    AWSServiceConfiguration* configuration = [UserManager sharedManager].configuration;
    [AWSS3 registerS3WithConfiguration:configuration forKey:@"Sender"];
    AWSS3* s3 = [AWSS3 S3ForKey:@"Sender"];
    
    NSString* filename = [self serverAvatarImageFilename];
    NSData* data = UIImageJPEGRepresentation(image, 90.0f);
    DDLogInfo(@"Upload avatar image %@ %d bytes", filename, (int)data.length);

    AWSS3PutObjectRequest* putRequest = [AWSS3PutObjectRequest new];
    putRequest.bucket = @"liverosaryavatars";
    putRequest.key = filename;
    putRequest.contentLength = @(data.length);
    putRequest.ACL = AWSS3BucketCannedACLPublicRead;
    putRequest.contentType = @"image/jpeg";
    putRequest.body = data;
    
    AWSTask* task = [s3 putObject:putRequest];
    [task continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        if(task.error)
        {
            DDLogError(@"Error uploading avatar image %@", task.error);
            safeBlock(completion, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Exception uploading avatar image %@", task.exception);
            safeBlock(completion, [NSError errorWithDomain:ErrorDomainUserManager code:-11 userInfo:nil]);
        }
        else
        {
            DDLogInfo(@"Avatar image upload complete");
            
            [data writeToFile:[self avatarImagePath] atomically:YES];
            [self loadAvatarImage];
            
            safeBlock(completion, nil);
        }
        
        return [AWSTask taskWithResult:nil];
    }];
    
}

- (void)downloadAvatarImageWithCompletion:(void (^)(NSError* error))completion
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    manager.responseSerializer = self;
    
    NSString* URLString = [NSString stringWithFormat:@"https://s3.amazonaws.com/liverosaryavatars/%@", [self serverAvatarImageFilename]];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    DDLogDebug(@"Downloading avatar image %@", URLString);
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error)
        {
            DDLogError(@"Avatar download error: %@", error);
            safeBlock(completion, error);
        }
        else
        {
            NSData* data = (NSData*)responseObject;
            [data writeToFile:[self avatarImagePath] atomically:YES];
            
            safeBlock(completion, nil);
        }
    }];
    
    [dataTask resume];
}

- (void)loadAvatarImage
{
    if([[NSFileManager defaultManager] fileExistsAtPath:[self avatarImagePath] isDirectory:nil])
    {
        self.avatarImage = [UIImage imageWithContentsOfFile:[self avatarImagePath]];
    }
    else
    {
        self.avatarImage = [UIImage imageNamed:@"AvatarImage"];
    }
}

- (void)loginWithEmail:(NSString*)email password:(NSString*)password completion:(void (^)(NSError* error))completion
{
    [[self.authClient login:email password:password] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        self.email = email;
        self.password = password;
        
        LiveRosaryAuthenticationResponse* result = (LiveRosaryAuthenticationResponse*)task.result;
        self.currentUser = [[UserModel alloc] initWithDict:result.user];
        if(self.currentUser.avatar != nil && self.currentUser.avatar.integerValue != 0)
        {
            [self downloadAvatarImageWithCompletion:^(NSError *error) {
                [self loadAvatarImage];
            }];
        }
        
        [self initializeCognitoWithCompletion:completion];
        return [AWSTask taskWithResult:nil];
    }];
}

- (void)logoutWithCompletion:(void (^)(NSError* error))completion
{
    [self.authClient logout];
    [self.credentialsProvider clearCredentials];
    self.email = nil;
    self.password = nil;
    self.currentUser = nil;
    self.avatarImage = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[self avatarImagePath] error:nil];
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

- (void)updateUserInfoWithDictionary:(NSDictionary*)info completion:(void (^)(NSError* error))completion;
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSMutableDictionary* newDict = [info mutableCopy];
    newDict[@"email"] = self.email;
    newDict[@"password"] = self.password;
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:newDict options:0 error:nil];
    NSString* postLength = [NSString stringWithFormat:@"%d", (int)postData.length];
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:[NSURL URLWithString:@"https://9wwr7dvesk.execute-api.us-east-1.amazonaws.com/prod/UpdateUser"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:ApiKey forHTTPHeaderField:@"x-api-key"];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"%@ %@", response, responseObject);
            
            NSNumber* updated = (NSNumber*)responseObject[@"updated"];
            if(updated != nil && [updated integerValue] == 1)
            {
                safeBlock(completion, nil);
            }
            else
            {
                safeBlock(completion, [NSError errorWithDomain:ErrorDomainUserManager code:-12 userInfo:nil]);
            }
        }
    }];
    [dataTask resume];
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

- (void)changePassword:(NSString*)currentPassword newPassword:(NSString*)newPassword completion:(void (^)(NSError* error))completion;
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSData* postData = [NSJSONSerialization dataWithJSONObject:@{ @"email": self.currentUser.email, @"oldPassword": currentPassword, @"newPassword": newPassword } options:0 error:nil];
    NSString* postLength = [NSString stringWithFormat:@"%d", (int)postData.length];
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:[NSURL URLWithString:@"https://9wwr7dvesk.execute-api.us-east-1.amazonaws.com/prod/ChangePassword"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:ApiKey forHTTPHeaderField:@"x-api-key"];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"%@ %@", response, responseObject);
            
            NSNumber* changed = (NSNumber*)responseObject[@"changed"];
            if(changed != nil && [changed integerValue] == 1)
            {
                [self.authClient updatePassword:newPassword];
                
                safeBlock(completion, nil);
            }
            else
            {
                safeBlock(completion, [NSError errorWithDomain:ErrorDomainUserManager code:-11 userInfo:nil]);
            }
        }
    }];
    [dataTask resume];
}

#pragma mark - AFURLResponseSerialization

- (nullable id)responseObjectForResponse:(nullable NSURLResponse *)response
                                    data:(nullable NSData *)data
                                   error:(NSError * _Nullable __autoreleasing *)error
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    if(httpResponse.statusCode != 200)
    {
        *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil];
    }
    
    return data;
}

@end
