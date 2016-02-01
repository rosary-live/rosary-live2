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

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ seq:%@ created:%@ updated:%@ live:%@ user:%@", self.bid, self.sequence, [self.created dateForNumber], [self.updated dateForNumber], self.live, self.user];
}
@end
