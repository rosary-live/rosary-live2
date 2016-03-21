//
//  NSNumber+Utilities.m
//  LiveRosary
//
//  Created by richardtaylor on 1/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "NSNumber+Utilities.h"

@implementation NSNumber (Utilities)

- (NSDate*)dateForNumber
{
    return [NSDate dateWithTimeIntervalSince1970:self.integerValue];
}

- (NSString*)daysString
{
    if(self.integerValue == 0)
    {
        return @"None";
    }
    
    NSMutableString* ret = [NSMutableString new];
    for(Day day = 0; day <= DaySaturday; day++)
    {
        if([self dayOn:day])
        {
            if(ret.length > 0) [ret appendString:@" "];
            
            NSString* dayString = nil;
            switch(day)
            {
                case DaySunday: dayString = @"Su"; break;
                case DayMonday: dayString = @"M"; break;
                case DayTuesday: dayString = @"Tu"; break;
                case DayWednesday: dayString = @"We"; break;
                case DayThursday: dayString = @"Th"; break;
                case DayFriday: dayString = @"F"; break;
                case DaySaturday: dayString = @"Sa"; break;
            }
            
            [ret appendString:dayString];
        }
    }
    
    return [NSString stringWithString:ret];
}

- (BOOL)dayOn:(Day)day
{
    unsigned int mask = (unsigned int)1 << day;
    return (self.unsignedIntegerValue & mask) == mask;
}

- (NSInteger)hour
{
    return self.integerValue / 60;
}

- (NSInteger)minute
{
    return self.integerValue % 60;
}

@end
