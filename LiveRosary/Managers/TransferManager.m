//
//  TransferManager.m
//  LiveRosary
//
//  Created by richardtaylor on 1/21/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "TransferManager.h"
#import <AWSS3/AWSS3.h>
#import "UserManager.h"
#import <AFNetworking/AFNetworking.h>

@interface TransferManager () <AFURLResponseSerialization>

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
    
    AWSServiceConfiguration* configuration = [UserManager sharedManager].configuration;
    
    [AWSS3 registerS3WithConfiguration:configuration forKey:@"Sender"];
    AWSS3* s3 = [AWSS3 S3ForKey:@"Sender"];
    
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
        
        DDLogInfo(@"Sending sequence %d  %d bytes", (int)self.sequence, (int)data.length);
        AWSS3PutObjectRequest* putRequest = [AWSS3PutObjectRequest new];
        putRequest.bucket = @"liverosarybroadcast";
        putRequest.key = [NSString stringWithFormat:@"%@/%06d", self.broadcastId, (int)self.sequence];
        putRequest.contentLength = @(data.length);
        putRequest.ACL = AWSS3BucketCannedACLPublicRead;
        
        if(_sequence == 0)
        {
            putRequest.contentType = @"application/json";
        }
        else
        {
            putRequest.contentType = @"binary/octet-stream";
        }
        
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
            DDLogInfo(@"Send sequence %d  %d bytes", (int)self.sequence, (int)data.length);
            ++_sequence;
        }
    }
    
    DDLogInfo(@"TransferManager sendThread stopped");
}


- (void)startReceiving:(NSString*)broadcastId atSequence:(NSInteger)sequence
{
    _broadcastId = broadcastId;
    _sequence = sequence;
    _receiving = YES;
    
    [self performSelectorInBackground:@selector(receiveThread) withObject:nil];
}

- (void)stopReceiving
{
    _receiving = NO;
}

- (void)receiveThread
{
    DDLogInfo(@"TransferManager receiveThread starting");
    
    NSCondition* condition = [NSCondition new];
    __block NSDate* lastSuccessfulReceiveDate = nil;
    __block NSError* lastError;
    
    while(self.isReceiving)
    {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        manager.responseSerializer = self;
        
        NSURL *URL = [NSURL URLWithString:[self URLForBroadcastId:self.broadcastId andSequence:self.sequence]];
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        
        NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
            if (error)
            {
                DDLogError(@"TransferManager receive error: %@", error);
                lastError = error;
            }
            else
            {
                NSData* data = (NSData*)responseObject;
                //DDLogDebug(@"TransferManager downloaded sequence %d with %d bytes", (int)self.sequence, (int)data.length);
                lastSuccessfulReceiveDate = [NSDate date];
                lastError = nil;
                if(self.delegate && [self.delegate respondsToSelector:@selector(receivedData:forSequence:)])
                {
                    [self.delegate receivedData:data forSequence:self.sequence];
                    ++_sequence;
                }
            }
            
            [condition lock];
            [condition broadcast];
            [condition unlock];
            
        }];
        [dataTask resume];

        [condition lock];
        [condition wait];
        [condition unlock];
        
        if(lastError != nil)
        {
            if([[NSDate date] timeIntervalSinceDate:lastSuccessfulReceiveDate] > 30)
            {
                _receiving = NO;
            }
            else
            {
                [NSThread sleepForTimeInterval:1];
            }
        }
    }
    
    DDLogInfo(@"TransferManager receiveThread stopping");

}

- (nullable id)responseObjectForResponse:(nullable NSURLResponse *)response
                                    data:(nullable NSData *)data
                                   error:(NSError * _Nullable __autoreleasing *)error
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    if(httpResponse.statusCode != 200)
    {
        *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil];
    }
    
    return data;
}

- (NSString*)URLForBroadcastId:(NSString*)bid andSequence:(NSInteger)sequence
{
    return [NSString stringWithFormat:@"https://s3.amazonaws.com/liverosarybroadcast/%@/%06d", bid, (int)sequence];
}

@end
