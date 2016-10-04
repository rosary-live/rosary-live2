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
    //scanExpression.limit = @(100);
    
    CFTimeInterval startTime = CACurrentMediaTime();
    [[self.dynamoDBObjectMapper scan:[ScheduleModel class] expression:scanExpression] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        CFTimeInterval duration = CACurrentMediaTime() - startTime;
        
        if(task.error)
        {
            DDLogError(@"Scan failed. Error: [%@]", task.error);
            [self logWithName:@"Schedule SCAN Error" duration:duration count:0 error:task.error.description];
            safeBlock(completion, nil, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Scan failed. Exception: [%@]", task.exception);
            [self logWithName:@"Schedule SCAN Error" duration:duration count:0 error:task.exception.description];
            safeBlock(completion, nil, [NSError errorWithDomain:ErrorDomainDatabase code:ErrorException userInfo:@{ NSLocalizedDescriptionKey: task.exception.description }]);
        }
        else if(task.result)
        {
            AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
//            for(ScheduleModel* scheduledBroadcast in paginatedOutput.items)
//            {
//                DDLogDebug(@"Scheduled Broadcast: %@", scheduledBroadcast);
//            }
            
            _scheduledBroadcasts = paginatedOutput.items;
            [self logWithName:@"Schedule SCAN" duration:duration count:paginatedOutput.items.count error:nil];
            
            safeBlock(completion, paginatedOutput.items, nil);
        }
        
        return nil;
    }];
}

- (void)getScheduledBroadcastById:(NSString*)sid completion:(void (^)(ScheduleModel* scheduledBroadcast, NSError* error))completion
{
    CFTimeInterval startTime = CACurrentMediaTime();
    [[self.dynamoDBObjectMapper load:[ScheduleModel class] hashKey:sid rangeKey:nil] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        CFTimeInterval duration = CACurrentMediaTime() - startTime;
        
        if(task.error)
        {
            DDLogError(@"Load failed. Error: [%@]", task.error);
            [self logWithName:@"Schedule byId Error" duration:duration count:0 error:task.error.description];
            safeBlock(completion, nil, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Load failed. Exception: [%@]", task.exception);
            [self logWithName:@"Schedule byId Error" duration:duration count:0 error:task.exception.description];
            safeBlock(completion, nil, [NSError errorWithDomain:ErrorDomainDatabase code:ErrorException userInfo:@{ NSLocalizedDescriptionKey: task.exception.description }]);
        }
        else if(task.result)
        {
            ScheduleModel* scheduledBroadcast = task.result;
            //DDLogDebug(@"Scheduled Broadcast: %@", scheduledBroadcast);
            [self logWithName:@"Schedule byId" duration:duration count:1 error:nil];
            
            safeBlock(completion, scheduledBroadcast, nil);
        }
        
        return nil;
    }];
}

- (void)getScheduledBroadcastsByEmail:(NSString*)email completion:(void (^)(NSArray<ScheduleModel*>* scheduledBroadcasts, NSError* error))completion
{
    AWSDynamoDBScanExpression* scanExpression = [AWSDynamoDBScanExpression new];
    //scanExpression.limit = @(100);
    scanExpression.filterExpression = @"#atname = :val";
    scanExpression.expressionAttributeNames = @{ @"#atname": @"user" };
    scanExpression.expressionAttributeValues = @{ @":val": email };
    
    CFTimeInterval startTime = CACurrentMediaTime();
    [[self.dynamoDBObjectMapper scan:[ScheduleModel class] expression:scanExpression] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        CFTimeInterval duration = CACurrentMediaTime() - startTime;
        
        if(task.error)
        {
            DDLogError(@"Load failed. Error: [%@]", task.error);
            [self logWithName:@"Schedule byEmail Error" duration:duration count:0 error:task.error.description];
            safeBlock(completion, nil, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Load failed. Exception: [%@]", task.exception);
            [self logWithName:@"Schedule byEmail Error" duration:duration count:0 error:task.exception.description];
            safeBlock(completion, nil, [NSError errorWithDomain:ErrorDomainDatabase code:ErrorException userInfo:@{ NSLocalizedDescriptionKey: task.exception.description }]);
        }
        else if(task.result)
        {
            AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
//            for(ScheduleModel* scheduledBroadcast in paginatedOutput.items)
//            {
//                DDLogDebug(@"Scheduled Broadcast: %@", scheduledBroadcast);
//            }
            
            [self logWithName:@"Schedule byEmail" duration:duration count:paginatedOutput.items.count error:nil];
            
            safeBlock(completion, paginatedOutput.items, nil);
        }
        
        return nil;
    }];
}

@end
