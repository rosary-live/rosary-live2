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

- (id)initWithDict:(NSDictionary*)dict
{
    self = [super init];
    if(self != nil)
    {
        self.email = dict[@"email"];
        self.firstName = dict[@"firstName"];
        self.lastName = dict[@"lastName"];
        self.city = dict[@"city"];
        self.state = dict[@"state"];
        self.country = dict[@"country"];
        self.language = dict[@"language"];
        self.latitude = dict[@"lat"];
        self.longitude = dict[@"lon"];
        self.avatar = dict[@"avatar"];
        self.level = dict[@"level"];
    }
    
    return self;
}

- (UserLevel)userLevel
{
    if([self.level isEqualToString:@"admin"]) return UserLevelAdmin;
    else if([self.level isEqualToString:@"broadcaster"]) return UserLevelBroadcaster;
    else if([self.level isEqualToString:@"listener"]) return UserLevelListener;
    else return UserLevelBanned;
}

@end
