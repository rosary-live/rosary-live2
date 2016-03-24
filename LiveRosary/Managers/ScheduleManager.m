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

- (NSString*)reminderUserDefaultKeyForId:(NSString*)sid
{
    return [NSString stringWithFormat:@"REMINDER-%@", sid];
}

- (BOOL)notificationsEnabled
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)])
    {
        UIUserNotificationSettings* grantedSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        
        if (grantedSettings.types != UIUserNotificationTypeNone)
        {
            NSLog(@"Notifications permiossion granted");
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)reminderSetForBroadcastWithId:(NSString*)sid
{
    id val = [[NSUserDefaults standardUserDefaults] objectForKey:[self reminderUserDefaultKeyForId:sid]];
    if(val != nil)
    {
        return YES;
    }
    
    return NO;
}

- (void)addListenReminderForBroadcastWithId:(NSString*)sid completion:(void (^)(NSError* error))completion
{
    if(![self reminderSetForBroadcastWithId:sid])
    {
        UILocalNotification* localNotification = [[UILocalNotification alloc] init];
        localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:20];
        localNotification.alertBody = @"Your alert message";
        localNotification.timeZone = [NSTimeZone defaultTimeZone];
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.userInfo = @{ @"sid": sid };
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        
        NSData* data = [NSKeyedArchiver archivedDataWithRootObject:localNotification];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:[self reminderUserDefaultKeyForId:sid]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)removeListenReminderForBroadcastWithId:(NSString*)sid completion:(void (^)(NSError* error))completion
{
    NSData* data = [[NSUserDefaults standardUserDefaults] objectForKey:[self reminderUserDefaultKeyForId:sid]];
    if(data != nil)
    {
        UILocalNotification* localNotification = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:[self reminderUserDefaultKeyForId:sid]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
