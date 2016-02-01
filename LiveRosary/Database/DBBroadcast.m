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
    scanExpression.limit = @(100);
    
    [[self.dynamoDBObjectMapper scan:[BroadcastModel class] expression:scanExpression] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {

        if(task.error)
        {
            NSLog(@"The request failed. Error: [%@]", task.error);
            safeBlock(completion, nil, task.error);
        }
        else if(task.exception)
        {
            NSLog(@"The request failed. Exception: [%@]", task.exception);
        }
        else if(task.result)
        {
            AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
            for(BroadcastModel* broadcast in paginatedOutput.items)
            {
                NSLog(@"Broadcast: %@ %@", broadcast.bid, broadcast.sequence);
            }
            
            safeBlock(completion, paginatedOutput.items, nil);
        }
        
        return nil;
    }];
}

@end
