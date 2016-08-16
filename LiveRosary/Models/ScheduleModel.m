//
//  ScheduleModel.m
//  LiveRosary
//
//  Created by richardtaylor on 3/16/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "ScheduleModel.h"
#import "NSNumber+Utilities.h"

@implementation ScheduleModel

+ (NSString *)dynamoDBTableName {
    return @"LiveRosarySchedule";
}

+ (NSString *)hashKeyAttribute {
    return @"sid";
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ created:%@ updated:%@ user:%@ type:%@", self.sid, [self.created dateForNumber], [self.updated dateForNumber], self.user, self.type];
}

- (BOOL)isSingle
{
    return [self.type isEqualToString:@"single"];
}

- (BOOL)isRecurring
{
    return [self.type isEqualToString:@"recurring"];
}

- (BOOL)isActive
{
    NSDate* date = [NSDate date];
    
    if(self.isSingle)
    {
        return [date compare:[self.start dateForNumber]] == NSOrderedAscending;
    }
    else
    {
        return [date compare:[self.to dateForNumber]] == NSOrderedAscending;
        //return [date compare:[self.start dateForNumber]] == NSOrderedDescending && [date compare:[self.start dateForNumber]]  == NSOrderedAscending;
    }
}

#pragma mark - MKAnnotation

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(self.lat.doubleValue, self.lon.doubleValue);
}

- (NSString*)title
{
    return [NSString stringWithFormat:@"%@ - %@", self.name, self.language];
}

- (NSString*)subtitle
{
    if(self.isSingle)
    {
        return [NSString stringWithFormat:@"%@", [NSDateFormatter localizedStringFromDate:[self.updated dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
    }
    else
    {
        return [NSString stringWithFormat:@"%@ - %@", [NSDateFormatter localizedStringFromDate:[self.from dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], [NSDateFormatter localizedStringFromDate:[self.to dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle]];
    }
}

- (NSDate*)scheduledTimeForDate:(NSDate*)date
{
    NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute  fromDate:date];
    comps.hour = [self.at hour];
    comps.minute = [self.at minute];
    comps.second = 0;
    return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

- (NSDate*)nextScheduledBroadcast
{
    if(self.isActive)
    {
        if(self.isSingle)
        {
            return [self.start dateForNumber];
        }
        else
        {
            NSDate* now = [NSDate date];
            NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitWeekday fromDate:now];
            
            NSInteger currentWeekday = comps.weekday;
            NSNumber* currentTime = @(comps.hour * 60 + comps.minute);
            
            for(NSInteger idx = currentWeekday; idx < currentWeekday + 7; idx++)
            {
                NSInteger weekday = idx >= 7 ? idx - 7 : idx;
                if([self.days dayOn:weekday])
                {
                    if(idx == 0)
                    {
                        if(currentTime.integerValue < self.at.integerValue)
                        {
                            return [self scheduledTimeForDate:now];
                        }
                    }
                    else
                    {
                        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
                        dayComponent.day = idx;
                        NSDate* weekdayDate = [[NSCalendar currentCalendar] dateByAddingComponents:dayComponent toDate:now options:0];
                        return [self scheduledTimeForDate:weekdayDate];
                    }
                }
            }
        }
    }
    
    return nil;
}

@end
