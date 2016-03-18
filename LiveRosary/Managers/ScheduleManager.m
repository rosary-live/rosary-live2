//
//  ScheduleManager.m
//  LiveRosary
//
//  Created by richardtaylor on 3/16/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "ScheduleManager.h"

@implementation ScheduleManager

+ (instancetype)sharedManager
{
    static ScheduleManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)scheduledBroadcastsWithCompletion:(void (^)(NSArray<ScheduleModel*>* scheduledBroadcasts, NSError* error))completion
{
}

- (void)addScheduledBroadcastWithInfo:(NSDictionary*)info completion:(void (^)(NSString* sid, NSError* error))completion
{
}

- (void)updateScheduledBroadcastWithInfo:(NSDictionary*)info completion:(void (^)(NSError* error))completion
{
}

- (void)removeScheduledBroadcastWithId:(NSString*)sid completion:(void (^)(NSError* error))completion
{
}

- (void)addListenReminderForBroadcastWithId:(NSString*)sid completion:(void (^)(NSError* error))completion
{
}

@end
