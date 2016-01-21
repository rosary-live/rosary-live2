//
//  UserModel.m
//  LiveRosary
//
//  Created by richardtaylor on 1/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "UserModel.h"

@implementation UserModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"URL": @"url",
             @"HTMLURL": @"html_url",
             @"number": @"number",
             @"state": @"state",
             @"reporterLogin": @"user.login",
             @"assignee": @"assignee",
             @"updatedAt": @"updated_at"
             };
}
@end
