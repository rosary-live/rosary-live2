//
//  UserModel.m
//  LiveRosary
//
//  Created by richardtaylor on 1/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "UserModel.h"

@implementation UserModel

+ (NSString *)dynamoDBTableName {
    return @"LiveRosaryUsers";
}

+ (NSString *)hashKeyAttribute {
    return @"email";
}

@end
