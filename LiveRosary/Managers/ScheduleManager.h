//
//  ScheduleManager.h
//  LiveRosary
//
//  Created by richardtaylor on 3/16/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScheduleModel.h"

@interface ScheduleManager : NSObject

+ (instancetype)sharedManager;

- (void)scheduledBroadcastsWithCompletion:(void (^)(NSArray<ScheduleModel*>* scheduledBroadcasts, NSError* error))completion;

- (void)addScheduledBroadcastWithInfo:(NSDictionary*)info completion:(void (^)(NSString* sid, NSError* error))completion;
- (void)updateScheduledBroadcastWithInfo:(NSDictionary*)info completion:(void (^)(NSError* error))completion;
- (void)removeScheduledBroadcastWithId:(NSString*)sid completion:(void (^)(NSError* error))completion;

- (void)addListenReminderForBroadcastWithId:(NSString*)sid completion:(void (^)(NSError* error))completion;

@end
