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
    
    DDLogDebug(@"POST %@: %@", method, dictionary);
    
    CFTimeInterval startTime = CACurrentMediaTime();
    NSURLSessionDataTask *dataTask = [self.manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if(error != nil)
        {
            DDLogError(@"POST %@ error: %@", method, error);
            [[AnalyticsManager sharedManager] logRequest:request response:(NSHTTPURLResponse*)response duration:CACurrentMediaTime() - startTime successful:NO message:nil error:error.description];
            safeBlock(completion, nil, error);
        }
        else
        {
            DDLogDebug(@"POST %@ response: %@ %@", method, response, responseObject);
            
            NSNumber* success = responseObject[@"success"];
            NSError* errorReturn = nil;
            if(success != nil && !success.boolValue)
            {
                DDLogError(@"LiveRosary API Error for %@: %@ - %@", method, responseObject[@"message"], responseObject[@"error"]);
                errorReturn = [NSError errorWithDomain:@"" code:0 userInfo:@{ NSLocalizedDescriptionKey: responseObject[@"message"] }];
            }
            
            [[AnalyticsManager sharedManager] logRequest:request response:(NSHTTPURLResponse*)response duration:CACurrentMediaTime() - startTime successful:success.boolValue message:responseObject[@"message"] error:responseObject[@"error"]];

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

- (void)lostPasswordWithEmail:(NSString*)email link:(NSString*)link completion:(void (^)(NSString* token, NSError* error))completion
{
    NSDictionary* dictionary = @{ @"email": email, @"link": link };
    
    [self postMethod:@"LostPassword" withDictionary:dictionary completion:^(id response, NSError *error) {
        NSDictionary* dict = response;
        safeBlock(completion, dict[@"token"], error);
    }];
}

- (void)resetPasswordWithToken:(NSString*)token newPassword:(NSString*)newPassword forEmail:(NSString*)email completion:(void (^)(NSError* error))completion
{
    NSDictionary* dictionary = @{ @"email": email, @"token": token, @"newPassword": newPassword };
    
    [self postMethod:@"ResetPassword" withDictionary:dictionary completion:^(id response, NSError *error) {
        safeBlock(completion, error);
    }];
}

- (void)requestBroadcastForEmail:(NSString*)email completion:(void (^)(NSError* error))completion {
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

- (void)reportBroadcast:(BroadcastModel*)broadcast reporterEmail:(NSString*)reporterEmail reason:(NSString*)reason link:(NSString*)link completion:(void (^)(NSError* error))completion
{
    NSDictionary* settings = @{
                               @"version": @(1),
                               @"bid": broadcast.bid,
                               @"reporter_email": reporterEmail,
                               @"reportee_email": broadcast.user,
                               @"reason": reason,
                               @"link": link
                               };
    
    [self postMethod:@"Report" withDictionary:settings completion:^(id response, NSError *error) {
        safeBlock(completion, error);
    }];
}

- (void)updateUserWithEmail:(NSString*)email toLevel:(NSString*)level adminEmail:(NSString*)adminEmail adminPassword:(NSString*)adminPassword completion:(void (^)(NSError* error))completion
{
    NSDictionary* dictionary = @{ @"email": adminEmail, @"password": adminPassword, @"updateEmail": email, @"updateLevel": level };
    
    [self postMethod:@"UpdateUserLevel" withDictionary:dictionary completion:^(id response, NSError *error) {
        safeBlock(completion, error);
    }];
}

- (void)updateUserForBroadcastRequest:(NSString*)email approve:(BOOL)approve adminEmail:(NSString*)adminEmail adminPassword:(NSString*)adminPassword completion:(void (^)(NSError* error))completion {
    NSDictionary* dictionary = @{ @"email": adminEmail, @"password": adminPassword, @"updateEmail": email, @"broadcastApprove": @(approve) };
    
    [self postMethod:@"UpdateUserLevel" withDictionary:dictionary completion:^(id response, NSError *error) {
        safeBlock(completion, error);
    }];
}

- (void)startBroadcastingWithEmail:(NSString*)email andBroadcastId:(NSString*)bid completion:(void (^)(NSError* error))completion
{
    NSDictionary* dictionary = @{
                                 @"email": email,
                                 @"bid": bid
                                 };
    
    [self postMethod:@"StartBroadcasting" withDictionary:dictionary completion:^(id response, NSError *error) {
        safeBlock(completion, error);
    }];
}

- (void)startListeningWithEmail:(NSString*)email andBroadcastId:(NSString*)bid completion:(void (^)(NSError* error))completion
{
    NSDictionary* dictionary = @{
                                 @"email": email,
                                 @"bid": bid
                                 };
    
    [self postMethod:@"StartListening" withDictionary:dictionary completion:^(id response, NSError *error) {
        safeBlock(completion, error);
    }];
}

- (void)sendMessage:(NSDictionary*)message toEmail:(NSString*)email completion:(void (^)(NSError* error))completion
{
    NSDictionary* dictionary = @{
                                 @"email": email,
                                 @"message": message
                                 };
    
    [self postMethod:@"SendMessage" withDictionary:dictionary completion:^(id response, NSError *error) {
        safeBlock(completion, error);
    }];
}

- (void)sendMessage:(NSDictionary*)message toBroadcast:(NSString*)bid completion:(void (^)(NSError* error))completion
{
    NSDictionary* dictionary = @{
                                 @"bid": bid,
                                 @"message": message
                                 };
    
    [self postMethod:@"SendMessage" withDictionary:dictionary completion:^(id response, NSError *error) {
        safeBlock(completion, error);
    }];
}

@end
