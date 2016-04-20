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
#import "NSNumber+Utilities.h"

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
    return [NSString stringWithFormat:@"REMINDER-%@-%@", [UserManager sharedManager].email, sid];
}

- (BOOL)notificationsEnabled
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)])
    {
        UIUserNotificationSettings* grantedSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        
        if (grantedSettings.types != UIUserNotificationTypeNone)
        {
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

- (void)addReminderForScheduledBroadcast:(ScheduleModel*)schedule broadcaster:(BOOL)broadcaster
{
    if(![self reminderSetForBroadcastWithId:schedule.sid])
    {
        UILocalNotification* localNotification = [[UILocalNotification alloc] init];
        localNotification.fireDate = [[schedule nextScheduledBroadcast] dateByAddingTimeInterval:-900]; // - 15 minutes
        
        if(schedule.isSingle)
        {
            localNotification.alertBody = [NSString stringWithFormat:@"Broadcast coming up at %@", [NSDateFormatter localizedStringFromDate:[schedule.start dateForNumber] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle]];
        }
        else
        {
            localNotification.alertBody = [NSString stringWithFormat:@"Broadcast coming up at %@", [schedule.at time]];
            localNotification.repeatInterval = NSCalendarUnitYear;
        }
        
        localNotification.timeZone = [NSTimeZone defaultTimeZone];
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.userInfo = @{ @"sid": schedule.sid,
                                        @"type": schedule.type,
                                        @"start": schedule.start,
                                        @"from": schedule.from,
                                        @"to": schedule.to,
                                        @"at": schedule.at,
                                        @"days": schedule.days,
                                        @"broadcaster": @(broadcaster)};
        
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        
        NSData* data = [NSKeyedArchiver archivedDataWithRootObject:localNotification];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:[self reminderUserDefaultKeyForId:schedule.sid]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)removeReminderForScheduledBroadcast:(ScheduleModel*)schedule
{
    NSData* data = [[NSUserDefaults standardUserDefaults] objectForKey:[self reminderUserDefaultKeyForId:schedule.sid]];
    if(data != nil)
    {
        UILocalNotification* localNotification = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:[self reminderUserDefaultKeyForId:schedule.sid]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)cleanupNotifications
{
    NSArray<UILocalNotification *>* notifications = [UIApplication sharedApplication].scheduledLocalNotifications;
    NSLog(@"notifications: %@", notifications);
    for(UILocalNotification* notification in notifications)
    {
        if(notification.userInfo[@"sid"] != nil)
        {
            ScheduleModel* schedule = [ScheduleModel new];
            schedule.sid = notification.userInfo[@"sid"];
            schedule.type = notification.userInfo[@"type"];
            schedule.start = notification.userInfo[@"start"];
            schedule.from = notification.userInfo[@"from"];
            schedule.to = notification.userInfo[@"to"];
            schedule.at = notification.userInfo[@"at"];
            schedule.days = notification.userInfo[@"days"];
            
            BOOL broadcaster = notification.userInfo[@"broadcaster"] ? ((NSNumber*)notification.userInfo[@"broadcaster"]).boolValue : NO;
            
            if(schedule.isRecurring)
            {
                if([[NSDate date] compare:notification.fireDate] == NSOrderedDescending)
                {
                    [self removeReminderForScheduledBroadcast:schedule];
                    
                    if(schedule.isActive)
                    {
                        [self addReminderForScheduledBroadcast:schedule broadcaster:broadcaster];
                    }
                }
            }
        }
    }
}

- (void)configureNotifications
{
    UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings* mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
}

- (void)handleLocalNotification:(UILocalNotification*)notification
{
    [UIAlertView bk_showAlertViewWithTitle:@"Reminder" message:notification.alertBody cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
}

@end
