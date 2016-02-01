//
//  DBBase.m
//  LiveRosary
//
//  Created by richardtaylor on 1/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "DBBase.h"
#import "UserManager.h"

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

@end
