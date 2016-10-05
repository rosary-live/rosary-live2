//
//  BroadcastModel.m
//  LiveRosary
//
//  Created by richardtaylor on 1/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "BroadcastModel.h"
#import "NSNumber+Utilities.h"

@implementation BroadcastModel

+ (NSString *)dynamoDBTableName {
    return @"LiveRosaryBroadcast";
}

+ (NSString *)hashKeyAttribute {
    return @"bid";
}

- (BOOL)isLive
{
    BOOL live = self.live.integerValue != 0;
    NSInteger secondsSinceLastUpdate = [[NSDate date] timeIntervalSince1970] - self.updated.integerValue;
    return  live && secondsSinceLastUpdate < 60;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ seq:%@ created:%@ updated:%@ live:%@ user:%@ lang:%@", self.bid, self.sequence, [self.created dateForNumber], [self.updated dateForNumber], self.live, self.user, self.language];
}

#pragma mark - MKAnnotation

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(self.lat.doubleValue, self.lon.doubleValue);
}

- (NSString*)title
{
    return nil;
//    return [NSString stringWithFormat:@"%@ - %@", self.name, self.language];
}

- (NSString*)subtitle
{
    return nil;
//    return [NSString stringWithFormat:@"%@ %@",[NSDateFormatter localizedStringFromDate:[self.updated dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle], self.isLive ? @"LIVE" : @"ENDED"];
}

@end
