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
#import "LiveRosaryService.h"

NSString * const ErrorDomainUserManager = @"ErrorDomainUserManager";
NSInteger const ErrorCodeUserManager_Exception = 1;
NSString * const UserDefaultEmail = @"UserDefaultEmail";
NSString * const UserDefaultPassword = @"UserDefaultPassword";

NSString * const NotificationUserLoggedIn = @"NotificationUserLoggedIn";
NSString * const NotificationUserLoggedOut = @"NotificationUserLoggedOut";

@interface UserManager() <AFURLResponseSerialization>
@property (nonatomic, strong) AWSCognitoCredentialsProvider* credentialsProvider;
@property (nonatomic, strong) LiveRosaryAuthenticationClient* authClient;
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

- (NSDictionary*)userDictionary
{
    return  @{
              @"email": self.currentUser.email,
              @"firstName": self.currentUser.firstName,
              @"lastName": self.currentUser.lastName,
              @"city": self.currentUser.city,
              @"state": self.currentUser.state,
              @"country": self.currentUser.country,
              @"language": self.currentUser.language,
              @"lat": self.currentUser.latitude,
              @"lon": self.currentUser.longitude,
              };
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

- (BOOL)isAuthenticated
{
    return self.currentUser != nil && self.currentUser.email != nil;
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
            if(task.error != nil)
            {
                if(completion) completion(task.error);
                return [AWSTask taskWithResult:nil];
            }
            else
            {
                return [[self.configuration.credentialsProvider refresh] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
                    
                    if(task.error != nil)
                    {
                        if(completion) completion(task.error);
                    }
                    else
                    {
                        self.currentUser = [[UserModel alloc] initWithDict:((LiveRosaryAuthenticatedIdentityProvider*)identityProvider).user];
                        [self loadAvatarImage];
                        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationUserLoggedIn object:nil];
                        
                        if(completion) completion(nil);
                    }
                    
                    return [AWSTask taskWithResult:nil];
                }];
            }
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
    [[LiveRosaryService sharedService] createUserWithDictionary:dictionary completion:^(NSError *error) {
        if(error != nil)
        {
            safeBlock(completion, error);
        }
        else
        {
            [self loginWithEmail:dictionary[@"email"] password:dictionary[@"password"] completion:completion];
        }
    }];
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
        if(task.error != nil)
        {
            safeBlock(completion, task.error);
            return [AWSTask taskWithError:task.error];
        }
        else
        {
            LiveRosaryAuthenticationResponse* result = (LiveRosaryAuthenticationResponse*)task.result;
            self.email = email;
            self.password = password;
            self.currentUser = [[UserModel alloc] initWithDict:result.user];
            if(self.currentUser.avatar != nil && self.currentUser.avatar.integerValue != 0)
            {
                [self downloadAvatarImageWithCompletion:^(NSError *error) {
                    [self loadAvatarImage];
                }];
            }
            
            [self initializeCognitoWithCompletion:completion];
            return [AWSTask taskWithResult:nil];
        }
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
    NSMutableDictionary* newDict = [info mutableCopy];
    newDict[@"email"] = self.email;
    newDict[@"password"] = self.password;
    
    [[LiveRosaryService sharedService] updateUserWithDictionary:newDict completion:^(NSError *error) {
        if(error == nil)
        {
            self.currentUser.firstName = info[@"firstName"];
            self.currentUser.lastName = info[@"lastName"];
            self.currentUser.city = info[@"city"];
            self.currentUser.state = info[@"state"];
            self.currentUser.country = info[@"country"];
            self.currentUser.language = info[@"language"];
            self.currentUser.avatar = info[@"avatar"];
            self.currentUser.latitude = info[@"lat"];
            self.currentUser.longitude = info[@"lon"];
        }
        
        safeBlock(completion, error);
    }];
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
    [[LiveRosaryService sharedService] changePassword:currentPassword newPassword:newPassword forEmail:self.currentUser.email completion:^(NSError *error) {
        if(error != nil)
        {
            safeBlock(completion, error);
        }
        else
        {
            [self.authClient updatePassword:newPassword];
            safeBlock(completion, nil);
        }
    }];
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
