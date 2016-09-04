//
//  LiveRosary.h
//  LiveRosary
//
//  Created by richardtaylor on 3/18/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BroadcastModel.h"

@interface LiveRosaryService : NSObject

+ (instancetype)sharedService;

- (void)loginWithEmail:(NSString*)email andPassword:(NSString*)password completion:(void (^)(id result, NSError* error))completion;
- (void)createUserWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSError* error))completion;
- (void)updateUserWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSError* error))completion;
- (void)changePassword:(NSString*)currentPassword newPassword:(NSString*)newPassword forEmail:(NSString*)email completion:(void (^)(NSError* error))completion;
- (void)lostPasswordWithEmail:(NSString*)email link:(NSString*)link completion:(void (^)(NSString* token, NSError* error))completion;
- (void)resetPasswordWithToken:(NSString*)token newPassword:(NSString*)newPassword forEmail:(NSString*)email completion:(void (^)(NSError* error))completion;
- (void)requestBroadcastForEmail:(NSString*)email completion:(void (^)(NSError* error))completion;

- (void)addScheduledBroadcastWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSError* error))completion;
- (void)updateScheduledBroadcastWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSError* error))completion;
- (void)removeScheduledBroadcastWithSID:(NSString*)sid completion:(void (^)(NSError* error))completion;

- (void)reportBroadcast:(BroadcastModel*)broadcast reporterEmail:(NSString*)reporterEmail reason:(NSString*)reason link:(NSString*)link completion:(void (^)(NSError* error))completion;

- (void)updateUserWithEmail:(NSString*)email toLevel:(NSString*)level adminEmail:(NSString*)adminEmail adminPassword:(NSString*)adminPassword completion:(void (^)(NSError* error))completion;

- (void)startBroadcastingWithEmail:(NSString*)email andBroadcastId:(NSString*)bid completion:(void (^)(NSError* error))completion;
- (void)startListeningWithEmail:(NSString*)email andBroadcastId:(NSString*)bid completion:(void (^)(NSError* error))completion;
- (void)sendMessage:(NSDictionary*)message toEmail:(NSString*)email completion:(void (^)(NSError* error))completion;
- (void)sendMessage:(NSDictionary*)message toBroadcast:(NSString*)bid completion:(void (^)(NSError* error))completion;

@end
