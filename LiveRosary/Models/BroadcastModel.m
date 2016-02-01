//
//  BroadcastModel.m
//  LiveRosary
//
//  Created by richardtaylor on 1/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "BroadcastModel.h"

@implementation BroadcastModel

+ (NSString *)dynamoDBTableName {
    return @"LiveRosaryBroadcast";
}

+ (NSString *)hashKeyAttribute {
    return @"bid";
}

@end
