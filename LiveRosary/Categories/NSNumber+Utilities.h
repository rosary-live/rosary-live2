//
//  NSNumber+Utilities.h
//  LiveRosary
//
//  Created by richardtaylor on 1/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, Day) {
    DaySunday,
    DayMonday,
    DayTuesday,
    DayWednesday,
    DayThursday,
    DayFriday,
    DaySaturday
};

@interface NSNumber (Utilities)

- (NSDate*)dateForNumber;
- (NSString*)daysString;
- (BOOL)dayOn:(Day)day;
- (NSInteger)hour;
- (NSInteger)minute;

@end
