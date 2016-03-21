//
//  ScheduleManager.m
//  LiveRosary
//
//  Created by richardtaylor on 3/16/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "ScheduleManager.h"
#import "DBSchedule.h"
#import "LiveRosaryService.h"
#import "NSString+Utilities.h"
#import "UserManager.h"

NSTimeInterval const kMinIntervalBetweenUpdates = 60.0;

@interface ScheduleManager ()

@property (nonatomic, strong) NSArray<ScheduleModel*>* myScheduledBroadcasts;

@property (nonatomic, strong) NSDate* lastAllUpdate;
@property (nonatomic, strong) NSDate* lastMyUpdate;

@end

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

- (void)allScheduledBroadcastsWithCompletion:(void (^)(NSArray<ScheduleModel*>* scheduledBroadcasts, NSError* error))completion
{
    if(self.lastAllUpdate == nil || [[NSDate date] timeIntervalSinceDate:self.lastAllUpdate] > kMinIntervalBetweenUpdates)
    {
        [[DBSchedule sharedInstance] updateScheduledBroadcastsWithCompletion:^(NSArray<ScheduleModel *> *scheduledBroadcasts, NSError *error) {
            if(error == nil)
            {
                self.lastAllUpdate = [NSDate date];
            }
            
            safeBlock(completion, scheduledBroadcasts, error);
        }];
    }
    else
    {
        safeBlock(completion, [DBSchedule sharedInstance].scheduledBroadcasts, nil);
    }
}

- (void)myScheduledBroadcastsWithCompletion:(void (^)(NSArray<ScheduleModel*>* scheduledBroadcasts, NSError* error))completion
{
    if(self.lastMyUpdate == nil || [[NSDate date] timeIntervalSinceDate:self.lastMyUpdate] > kMinIntervalBetweenUpdates)
    {
        [[DBSchedule sharedInstance] getScheduledBroadcastsByEmail:[UserManager sharedManager].email completion:^(NSArray<ScheduleModel *> *scheduledBroadcasts, NSError *error) {
            if(error == nil)
            {
                self.lastMyUpdate = [NSDate date];
                self.myScheduledBroadcasts = scheduledBroadcasts;
            }
            
            safeBlock(completion, self.myScheduledBroadcasts, error);
        }];
    }
    else
    {
        safeBlock(completion, self.myScheduledBroadcasts, nil);
    }
}

- (void)addScheduledBroadcastWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSString* sid, NSError* error))completion
{
    NSString* sid = [NSString UUID];
    NSMutableDictionary* dictWithSID = [dictionary mutableCopy];
    dictWithSID[@"sid"] = sid;
    
    [[LiveRosaryService sharedService] addScheduledBroadcastWithDictionary:dictWithSID completion:^(NSError *error) {
        if(error == nil)
        {
            self.lastMyUpdate = nil;
        }
        
        safeBlock(completion, sid, error);
    }];
}

- (void)updateScheduledBroadcastWithDictionary:(NSDictionary*)dictionary completion:(void (^)(NSError* error))completion
{
    [[LiveRosaryService sharedService] updateScheduledBroadcastWithDictionary:dictionary completion:^(NSError *error) {
        if(error == nil)
        {
            self.lastMyUpdate = nil;
        }
        
        safeBlock(completion, error);
    }];
}

- (void)removeScheduledBroadcastWithId:(NSString*)sid completion:(void (^)(NSError* error))completion
{
    [[LiveRosaryService sharedService] removeScheduledBroadcastWithSID:sid completion:^(NSError *error) {
        if(error == nil)
        {
            self.lastMyUpdate = nil;
        }
        
        safeBlock(completion, error);
    }];
}

- (void)addListenReminderForBroadcastWithId:(NSString*)sid completion:(void (^)(NSError* error))completion
{
}

@end
