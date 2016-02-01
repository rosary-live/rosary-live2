//
//  UserManager.h
//  LiveRosary
//
//  Created by richardtaylor on 1/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AWSServiceConfiguration;

@interface UserManager : NSObject

@property (nonatomic, getter=isLoggedIn) BOOL loggedIn;
@property (nonatomic, strong) AWSServiceConfiguration* configuration;

+ (instancetype)sharedManager;

- (void)createUserWithEmail:(NSString*)email password:(NSString*)password completion:(void (^)(NSError* error))completion;
- (void)loginWithEmail:(NSString*)email password:(NSString*)password completion:(void (^)(NSError* error))completion;
- (BOOL)credentialsExpired;
- (void)refreshCredentialsWithCompletion:(void (^)(NSError* error))completion;
- (void)updateUserInfoWithDictionary:(NSDictionary*)info;
- (void)refreshTokenWithCompletion:(void (^)(NSError* error))completion;

@end
