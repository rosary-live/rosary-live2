//
//  DBUser.h
//  LiveRosary
//
//  Created by richardtaylor on 4/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "DBBase.h"
#import "UserModel.h"

@interface DBUser : DBBase

+ (instancetype)sharedInstance;

- (NSArray*)usersForLevel:(NSString*)level;
- (void)getUserByEmail:(NSString*)email completion:(void (^)(UserModel* user, NSError* error))completion;
- (void)getUsersByLevel:(NSString*)level reset:(BOOL)reset completion:(void (^)(NSArray<UserModel*>* allUsers, NSArray<UserModel*>* users, BOOL complete, NSError* error))completion;
- (BOOL)completeForLevel:(NSString*)level;

- (void)updateLevelForEmail:(NSString*)email from:(NSString*)fromLevel to:(NSString*)toLevel;

@end
