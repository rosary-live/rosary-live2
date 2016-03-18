//
//  DBSchedule.h
//  LiveRosary
//
//  Created by richardtaylor on 3/16/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "DBBase.h"
#import "ScheduleModel.h"

@interface DBSchedule : DBBase

@property (nonatomic, strong, readonly) NSArray<ScheduleModel*>* scheduledBroadcasts;

+ (instancetype)sharedInstance;

- (void)updateScheduledBroadcastsWithCompletion:(void (^)(NSArray<ScheduleModel*>* scheduledBroadcasts, NSError* error))completion;
- (void)getScheduledBroadcastById:(NSString*)sid completion:(void (^)(ScheduleModel* scheduledBroadcast, NSError* error))completion;

@end
