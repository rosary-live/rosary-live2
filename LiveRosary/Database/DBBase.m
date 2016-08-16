//
//  DBBase.m
//  LiveRosary
//
//  Created by richardtaylor on 1/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "DBBase.h"
#import "UserManager.h"

NSString * const ErrorDomainDatabase = @"ErrorDomainUserManager";
NSInteger const ErrorException = -900;

@implementation DBBase

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        [AWSDynamoDBObjectMapper registerDynamoDBObjectMapperWithConfiguration:[UserManager sharedManager].configuration objectMapperConfiguration:[AWSDynamoDBObjectMapperConfiguration new] forKey:@"DDB"];
        
        self.dynamoDBObjectMapper = [AWSDynamoDBObjectMapper DynamoDBObjectMapperForKey:@"DDB"];
    }
    return self;
}

- (void)logWithName:(NSString*)name duration:(CFTimeInterval)duration count:(NSInteger)count error:(NSString*)error
{
    [[AnalyticsManager sharedManager] event:@"DynamoDB" info:@{ @"Name": name,
                                                                @"Duration": @(duration),
                                                                @"Count": @(count),
                                                                @"Error": error != nil ? error : @"" }];
}

@end
