//
//  TransferManager.m
//  LiveRosary
//
//  Created by richardtaylor on 1/21/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "TransferManager.h"
#import <AWSS3/AWSS3.h>

@interface TransferManager ()

@property (nonatomic, strong) NSMutableArray<NSData*>* sendQueue;
@property (nonatomic, strong) NSCondition* sendCondition;

@end

@implementation TransferManager

+ (instancetype)sharedManager
{
    static TransferManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if(self = [super init])
    {
        self.sendQueue = [NSMutableArray new];
        self.sendCondition = [NSCondition new];
    }
    return self;
}

- (void)startSending:(NSString*)broadcastId
{
    _broadcastId = broadcastId;
    _sequence = 0;
    _sending = YES;
    
    [self performSelectorInBackground:@selector(sendThread) withObject:nil];
}

- (void)stopSending
{
    _sending = NO;
}

- (void)addSequenceData:(NSData*)data
{
    [self.sendCondition lock];
    
    @synchronized(self.sendQueue)
    {
        [self.sendQueue addObject:data];
    }
    
    [self.sendCondition broadcast];
    [self.sendCondition unlock];
}

- (void)sendThread
{
    DDLogInfo(@"TransferManager sendThread starting");
    
    AWSServiceConfiguration* conf = [AWSServiceManager defaultServiceManager].defaultServiceConfiguration;
    id<AWSCredentialsProvider> provider = conf.credentialsProvider;
    AWSS3* s3 = [AWSS3 defaultS3];
    
    while(self.isSending)
    {
        [self.sendCondition lock];
        
        if(self.sendQueue.count == 0)
        {
            [self.sendCondition wait];
        }
        
        NSData* data = nil;
        @synchronized(self.sendQueue)
        {
            data = [self.sendQueue objectAtIndex:0];
            [self.sendQueue removeObjectAtIndex:0];
        }
        
        [self.sendCondition unlock];
        
        DDLogDebug(@"Sending sequence %d  %d bytes", (int)self.sequence, (int)data.length);
        AWSS3PutObjectRequest* putRequest = [AWSS3PutObjectRequest new];
        putRequest.bucket = @"liverosarybroadcast";
        putRequest.key = [NSString stringWithFormat:@"%@/%06d", self.broadcastId, (int)self.sequence];
        putRequest.body = data;
        
        AWSTask* task = [s3 putObject:putRequest];
        [task waitUntilFinished];
        
        if(task.error)
        {
            DDLogError(@"Send sequence %d error: %@", (int)self.sequence, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Send sequence %d exception: %@", (int)self.sequence, task.exception);
        }
        else
        {
            DDLogDebug(@"Send sequence %d  %d bytes", (int)self.sequence, (int)data.length);
            ++_sequence;
        }
    }
    
    DDLogInfo(@"TransferManager sendThread stopped");
}

@end
