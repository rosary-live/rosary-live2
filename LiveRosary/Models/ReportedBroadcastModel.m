//
//  ReportedBroadcast.m
//  LiveRosary
//
//  Created by Richard Taylor on 4/14/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "ReportedBroadcastModel.h"
#import "NSNumber+Utilities.h"

@implementation ReportedBroadcastModel

+ (NSString *)dynamoDBTableName {
    return @"LiveRosaryReport";
}

+ (NSString *)hashKeyAttribute {
    return @"bid";
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ seq:%@ created:%@ user:%@", self.bid, self.sequence, [self.created dateForNumber], self.b_email];
}

#pragma mark - MKAnnotation

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(self.b_lat.doubleValue, self.b_lon.doubleValue);
}

- (NSString*)title
{
    return nil;
//    return [NSString stringWithFormat:@"%@ - %@", self.b_name, self.b_language];
}

- (NSString*)subtitle
{
    return nil;
//    return [NSString stringWithFormat:@"%@", self.reason];
}

@end
