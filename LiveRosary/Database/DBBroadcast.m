//
//  DBBroadcast.m
//  LiveRosary
//
//  Created by richardtaylor on 1/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "DBBroadcast.h"

@implementation DBBroadcast

+ (instancetype)sharedInstance
{
    static DBBroadcast* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)updateBroadcastsWithCompletion:(void (^)(NSArray<BroadcastModel*>* broadcasts, NSError* error))completion
{
    AWSDynamoDBScanExpression* scanExpression = [AWSDynamoDBScanExpression new];
    //scanExpression.limit = @(100);
    
    CFTimeInterval startTime = CACurrentMediaTime();
    [[self.dynamoDBObjectMapper scan:[BroadcastModel class] expression:scanExpression] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        CFTimeInterval duration = CACurrentMediaTime() - startTime;
        
        if(task.error)
        {
            DDLogError(@"Scan failed. Error: [%@]", task.error);
            [self logWithName:@"Broadcasts SCAN Error" duration:duration count:0 error:task.error.description];
            safeBlock(completion, nil, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Scan failed. Exception: [%@]", task.exception);
            [self logWithName:@"Broadcasts SCAN Error" duration:duration count:0 error:task.exception.description];
            safeBlock(completion, nil, [NSError errorWithDomain:ErrorDomainDatabase code:ErrorException userInfo:@{ NSLocalizedDescriptionKey: task.exception.description }]);
        }
        else if(task.result)
        {
            AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
            for(BroadcastModel* broadcast in paginatedOutput.items)
            {
                //DDLogDebug(@"Broadcast: %@", broadcast);
            }
            
            [self logWithName:@"Broadcasts SCAN" duration:duration count:paginatedOutput.items.count error:nil];
            safeBlock(completion, paginatedOutput.items, nil);
        }
        
        return nil;
    }];
}

- (void)getBroadcastById:(NSString*)bid completion:(void (^)(BroadcastModel* broadcast, NSError* error))completion
{
    CFTimeInterval startTime = CACurrentMediaTime();
    [[self.dynamoDBObjectMapper load:[BroadcastModel class] hashKey:bid rangeKey:nil] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        CFTimeInterval duration = CACurrentMediaTime() - startTime;

        if(task.error)
        {
            DDLogError(@"Load failed. Error: [%@]", task.error);
            [self logWithName:@"Broadcasts byId Error" duration:duration count:0 error:task.error.description];
            safeBlock(completion, nil, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Load failed. Exception: [%@]", task.exception);
            [self logWithName:@"Broadcasts byId Error" duration:duration count:0 error:task.exception.description];
            safeBlock(completion, nil, [NSError errorWithDomain:ErrorDomainDatabase code:ErrorException userInfo:@{ NSLocalizedDescriptionKey: task.exception.description }]);
        }
        else if(task.result)
        {
            BroadcastModel* broadcast = task.result;
            //DDLogDebug(@"Broadcast: %@", broadcast);
            [self logWithName:@"Broadcasts byId" duration:duration count:1 error:nil];
            
            safeBlock(completion, broadcast, nil);
        }
        
        return nil;
    }];
}

@end
