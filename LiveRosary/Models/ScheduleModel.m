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

@end
