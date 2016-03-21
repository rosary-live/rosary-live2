//
//  LiveRosary.m
//  LiveRosary
//
//  Created by richardtaylor on 3/18/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LiveRosaryService.h"
#import <AFNetworking/AFNetworking.h>

NSString* const kApiKey = @"hhpm1l5N771l3eZf7V4Lk8AjWyYgZbPM7XPPU8Jw";
NSString* const kBaseURL = @"https://9wwr7dvesk.execute-api.us-east-1.amazonaws.com/prod";

@interface LiveRosaryService ()

@property (nonatomic, strong) AFURLSessionManager* manager;
@end

@implementation LiveRosaryService

+ (instancetype)sharedService
{
    static LiveRosaryService* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if(self != nil)
    {
        NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    }
    return self;
}

- (NSURL*)urlWithMethod:(NSString*)method
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", kBaseURL, method]];
}

- (void)postMethod:(NSString*)method withDictionary:(NSDictionary*)dictionary completion:(void (^)(id response, NSError* error))completion
{
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString* postLength = [NSString stringWithFormat:@"%d", (int)postData.length];
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:[self urlWithMethod:method]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:kApiKey forHTTPHeaderField:@"x-api-key"];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *dataTask = [self.manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if(error != nil)
        {
            safeBlock(completion, nil, error);
        }
        else
        {
            NSNumber* success = responseObject[@"success"];
            NSError* errorReturn = nil;
            if(success != nil && ![success boolValue])
            {
                DDLogError(@"LiveRosary API Error for %@: %@ - %@", method, responseObject[@"message"], responseObject[@"error"]);
                errorReturn = [NSError errorWithDomain:@"" code:0 userInfo:@{ NSLocalizedDescriptionKey: responseObject[@"message"] }];
            }
            
            safeBlock(completion, responseObject, errorReturn);
        }
    }];
    [dataTask resume];
}

- (void)loginWithEmail:(NSString*)email andPassword:(NSString*)password completion:(void (^)(id result, NSError* error))completion
{
}

- (void)createUserWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSError* error))completion
{
    [self postMethod:@"CreateUser" withDictionary:dictionary completion:^(id response, NSError *error) {
        safeBlock(completion, error);
    }];
}

- (void)updateUserWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSError* error))completion
{
    [self postMethod:@"UpdateUser" withDictionary:dictionary completion:^(id response, NSError *error) {
        safeBlock(completion, error);
    }];
}

- (void)changePassword:(NSString*)currentPassword newPassword:(NSString*)newPassword forEmail:(NSString*)email completion:(void (^)(NSError* error))completion
{
    NSDictionary* dictionary = @{ @"email": email, @"oldPassword": currentPassword, @"newPassword": newPassword };
    
    [self postMethod:@"ChangePassword" withDictionary:dictionary completion:^(id response, NSError *error) {
        safeBlock(completion, error);
    }];
}

- (void)addScheduledBroadcastWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSError* error))completion
{
    NSMutableDictionary* dictWithAction = [dictionary mutableCopy];
    dictWithAction[@"action"] = @"add";
    
    [self postMethod:@"Schedule" withDictionary:dictWithAction completion:^(id response, NSError *error) {
        safeBlock(completion, error);
    }];
}

- (void)updateScheduledBroadcastWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSError* error))completion
{
    NSMutableDictionary* dictWithAction = [dictionary mutableCopy];
    dictWithAction[@"action"] = @"update";
    
    [self postMethod:@"Schedule" withDictionary:dictWithAction completion:^(id response, NSError *error) {
        safeBlock(completion, error);
    }];
}

- (void)removeScheduledBroadcastWithSID:(NSString*)sid completion:(void (^)(NSError* error))completion
{
    NSMutableDictionary* dictWithAction = [NSMutableDictionary new];
    dictWithAction[@"action"] = @"remove";
    dictWithAction[@"sid"] = sid;
    
    [self postMethod:@"Schedule" withDictionary:dictWithAction completion:^(id response, NSError *error) {
        safeBlock(completion, error);
    }];
}

@end