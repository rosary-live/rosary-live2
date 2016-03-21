//
//  UserManager.h
//  LiveRosary
//
//  Created by richardtaylor on 1/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserModel.h"

FOUNDATION_EXTERN NSString * const NotificationUserLoggedIn;
FOUNDATION_EXTERN NSString * const NotificationUserLoggedOut;

@class AWSServiceConfiguration;

@interface UserManager : NSObject

@property (nonatomic, getter=isLoggedIn) BOOL loggedIn;
@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) UserModel* currentUser;
@property (nonatomic, strong) UIImage* avatarImage;
@property (nonatomic, strong) AWSServiceConfiguration* configuration;
@property (nonatomic, strong, readonly) NSArray<NSString*>* languages;

+ (instancetype)sharedManager;

- (void)createUserWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSError* error))completion;
- (void)uploadAvatarImage:(UIImage*)image completion:(void (^)(NSError* error))completion;
- (void)loginWithEmail:(NSString*)email password:(NSString*)password completion:(void (^)(NSError* error))completion;
- (void)logoutWithCompletion:(void (^)(NSError* error))completion;
- (BOOL)credentialsExpired;
- (void)refreshCredentialsWithCompletion:(void (^)(NSError* error))completion;
- (void)updateUserInfoWithDictionary:(NSDictionary*)info completion:(void (^)(NSError* error))completion;
- (void)refreshTokenWithCompletion:(void (^)(NSError* error))completion;
- (void)changePassword:(NSString*)currentPassword newPassword:(NSString*)newPassword completion:(void (^)(NSError* error))completion;;

@end
