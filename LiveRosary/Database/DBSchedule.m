//
//  DBSchedule.m
//  LiveRosary
//
//  Created by richardtaylor on 3/16/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "DBSchedule.h"

@implementation DBSchedule

+ (instancetype)sharedInstance
{
    static DBSchedule* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)updateScheduledBroadcastsWithCompletion:(void (^)(NSArray<ScheduleModel*>* scheduledBroadcasts, NSError* error))completion
{
    AWSDynamoDBScanExpression* scanExpression = [AWSDynamoDBScanExpression new];
    scanExpression.limit = @(100);
    
    [[self.dynamoDBObjectMapper scan:[ScheduleModel class] expression:scanExpression] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        
        if(task.error)
        {
            DDLogError(@"Scan failed. Error: [%@]", task.error);
            safeBlock(completion, nil, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Scan failed. Exception: [%@]", task.exception);
            safeBlock(completion, nil, [NSError errorWithDomain:ErrorDomainDatabase code:ErrorException userInfo:@{ @"description": task.exception.description }]);
        }
        else if(task.result)
        {
            AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
            for(ScheduleModel* scheduledBroadcast in paginatedOutput.items)
            {
                DDLogDebug(@"Scheduled Broadcast: %@", scheduledBroadcast);
            }
            
            safeBlock(completion, paginatedOutput.items, nil);
        }
        
        return nil;
    }];
}

- (void)getScheduledBroadcastById:(NSString*)sid completion:(void (^)(ScheduleModel* scheduledBroadcast, NSError* error))completion
{
    [[self.dynamoDBObjectMapper load:[ScheduleModel class] hashKey:sid rangeKey:nil] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        if(task.error)
        {
            DDLogError(@"Load failed. Error: [%@]", task.error);
            safeBlock(completion, nil, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Load failed. Exception: [%@]", task.exception);
            safeBlock(completion, nil, [NSError errorWithDomain:ErrorDomainDatabase code:ErrorException userInfo:@{ @"description": task.exception.description }]);
        }
        else if(task.result)
        {
            ScheduleModel* scheduledBroadcast = task.result;
            DDLogDebug(@"Scheduled Broadcast: %@", scheduledBroadcast);
            
            safeBlock(completion, scheduledBroadcast, nil);
        }
        
        return nil;
    }];
}

@end
