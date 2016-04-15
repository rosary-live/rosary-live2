//
//  DBReportedBroadcast.m
//  LiveRosary
//
//  Created by Richard Taylor on 4/13/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "DBReportedBroadcast.h"

@implementation DBReportedBroadcast

+ (instancetype)sharedInstance
{
    static DBReportedBroadcast* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)updateReportedBroadcastsWithCompletion:(void (^)(NSArray<ReportedBroadcastModel*>* broadcasts, NSError* error))completion
{
    AWSDynamoDBScanExpression* scanExpression = [AWSDynamoDBScanExpression new];
    scanExpression.limit = @(100);
    
    CFTimeInterval startTime = CACurrentMediaTime();
    [[self.dynamoDBObjectMapper scan:[ReportedBroadcastModel class] expression:scanExpression] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        CFTimeInterval duration = CACurrentMediaTime() - startTime;
        
        if(task.error)
        {
            DDLogError(@"Scan failed. Error: [%@]", task.error);
            [self logWithName:@"Reported Broadcasts SCAN Error" duration:duration count:0 error:task.error.description];
            safeBlock(completion, nil, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Scan failed. Exception: [%@]", task.exception);
            [self logWithName:@"Reported Broadcasts SCAN Error" duration:duration count:0 error:task.exception.description];
            safeBlock(completion, nil, [NSError errorWithDomain:ErrorDomainDatabase code:ErrorException userInfo:@{ NSLocalizedDescriptionKey: task.exception.description }]);
        }
        else if(task.result)
        {
            AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
            for(ReportedBroadcastModel* broadcast in paginatedOutput.items)
            {
                DDLogDebug(@"Reported Broadcast: %@", broadcast);
            }
            
            [self logWithName:@"Reported Broadcasts SCAN" duration:duration count:paginatedOutput.items.count error:nil];
            safeBlock(completion, paginatedOutput.items, nil);
        }
        
        return nil;
    }];
}

@end
