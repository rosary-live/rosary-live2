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

@property (nonatomic, readonly) BOOL notificationsEnabled;

+ (instancetype)sharedManager;

- (void)clearCache;

- (void)allScheduledBroadcastsWithCompletion:(void (^)(NSArray<ScheduleModel*>* scheduledBroadcasts, NSError* error))completion;
- (void)myScheduledBroadcastsWithCompletion:(void (^)(NSArray<ScheduleModel*>* scheduledBroadcasts, NSError* error))completion;

- (void)addScheduledBroadcastWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSString* sid, NSError* error))completion;
- (void)updateScheduledBroadcastWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSError* error))completion;
- (void)removeScheduledBroadcastWithId:(NSString*)sid completion:(void (^)(NSError* error))completion;

- (BOOL)reminderSetForBroadcastWithId:(NSString*)sid;
- (void)addReminderForScheduledBroadcast:(ScheduleModel*)schedule broadcaster:(BOOL)broadcaster;
- (void)removeReminderForScheduledBroadcast:(ScheduleModel*)schedule;

- (void)configureNotifications;
- (void)cleanupNotifications;
- (void)handleLocalNotification:(UILocalNotification*)notification;

@end
