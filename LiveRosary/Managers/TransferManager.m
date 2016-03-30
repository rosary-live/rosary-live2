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

@interface SendWrapper : NSObject
@property (nonatomic, strong) NSString* filename;
@property (nonatomic) BOOL lastFile;
@end

@implementation SendWrapper
@end


@interface TransferManager () <AFURLResponseSerialization>

@property (nonatomic, strong) NSMutableArray<SendWrapper*>* sendQueue;
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
        
        AWSServiceConfiguration* configuration = [UserManager sharedManager].configuration;
        [AWSS3 registerS3WithConfiguration:configuration forKey:@"TestSender"];
        
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
    [self.sendCondition lock];
    [self.sendCondition broadcast];
    [self.sendCondition unlock];

    @synchronized(self.sendQueue)
    {
        [self.sendQueue removeAllObjects];
    }
}

- (void)addSequenceFile:(NSString *)filename lastFile:(BOOL)lastFile
{
    [self.sendCondition lock];
    
    @synchronized(self.sendQueue)
    {
        SendWrapper* wrapper = [SendWrapper new];
        wrapper.filename = filename;
        wrapper.lastFile = lastFile;
        [self.sendQueue addObject:wrapper];
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
            DDLogInfo(@"TransferManager sendThread waiting to send");
            [self.sendCondition wait];
        }
        
        DDLogInfo(@"Sending");
        SendWrapper* wrapper = nil;
        @synchronized(self.sendQueue)
        {
            wrapper = [self.sendQueue objectAtIndex:0];
            [self.sendQueue removeObjectAtIndex:0];
        }
        
        [self.sendCondition unlock];
        
        NSData* data = [NSData dataWithContentsOfFile:wrapper.filename];
        
        DDLogInfo(@"Sending sequence %d  %@  %d bytes", (int)self.sequence, wrapper.filename, (int)data.length);
        AWSS3PutObjectRequest* putRequest = [AWSS3PutObjectRequest new];
        putRequest.bucket = @"liverosarybroadcast";
        putRequest.key = [NSString stringWithFormat:@"%@/%06d",  self.broadcastId, (int)self.sequence];
        putRequest.contentLength = @(data.length);
        putRequest.ACL = AWSS3BucketCannedACLPublicRead;
        putRequest.metadata = @{ @"Last-File": wrapper.lastFile ? @"1" : @"0" };
        
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
            if(self.delegate && [self.delegate respondsToSelector:@selector(sentFile:forSequence:lastFile:)])
            {
                [self.delegate sentFile:wrapper.filename forSequence:_sequence lastFile:wrapper.lastFile];
            }
            
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
    __block NSDate* lastSuccessfulReceiveDate = [NSDate date];
    __block NSError* lastError;
    
    while(self.isReceiving)
    {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        manager.responseSerializer = self;
        
        NSString* URLString = [self URLForBroadcastId:self.broadcastId andSequence:self.sequence];
        NSURL *URL = [NSURL URLWithString:URLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        
        DDLogDebug(@"Downloading sequence %d from from %@", (int)self.sequence, URLString);
        NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
            if (error)
            {
                DDLogError(@"TransferManager receive error: %@", error);
                lastError = error;
            }
            else
            {
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                
                NSData* data = (NSData*)responseObject;
                DDLogDebug(@"TransferManager downloaded sequence %d with %d bytes", (int)self.sequence, (int)data.length);
                lastSuccessfulReceiveDate = [NSDate date];
                lastError = nil;
             
                NSString* lastFileHeader = httpResponse.allHeaderFields[@"x-amz-meta-last-file"];
                BOOL lastFile = lastFileHeader != nil && lastFileHeader.integerValue != 0;
                if(lastFile) NSLog(@"!!!!!!!!!!!!LAST FILE");
                if(self.delegate != nil && [self.delegate respondsToSelector:@selector(receivedFile:forSequence:lastFile:)])
                {
                    NSString* filename = [NSString filenameForBroadcastId:self.broadcastId andSequence:self.sequence];
                    [data writeToFile:filename atomically:NO];
                    [self.delegate receivedFile:filename forSequence:self.sequence lastFile:lastFile];
                    ++_sequence;
                }
                
                if(lastFile)
                {
                    _receiving = NO;
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
        
        if(!_receiving)
        {
            break;
        }
        
        if(lastError != nil)
        {
            if([[NSDate date] timeIntervalSinceDate:lastSuccessfulReceiveDate] > 60)
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

- (CFTimeInterval)uploadTestFileWithSize:(NSInteger)size
{
    AWSS3* s3 = [AWSS3 S3ForKey:@"TestSender"];
    
    char* bytes = malloc(size);
    NSData* data = [NSData dataWithBytesNoCopy:bytes length:size];
    
    AWSS3PutObjectRequest* putRequest = [AWSS3PutObjectRequest new];
    putRequest.bucket = @"liverosarybroadcast";
    putRequest.key = [NSString stringWithFormat:@"test/%@-%d",  [NSString UUID], (int)size];
    putRequest.contentLength = @(data.length);
    putRequest.ACL = AWSS3BucketCannedACLPublicRead;
    putRequest.metadata = @{ @"Test-File": @"1" };
    putRequest.contentType = @"binary/octet-stream";
    putRequest.body = data;
    
    CFTimeInterval startInterval = CACurrentMediaTime();
    AWSTask* task = [s3 putObject:putRequest];
    [task waitUntilFinished];
    
    if(task.error)
    {
        return 0.0;
    }
    else if(task.exception)
    {
        return 0.0;
    }
    else
    {
        return (CFTimeInterval)data.length / (CACurrentMediaTime() - startInterval);
    }

}

- (void)checkBroadcastBandwidthWithCompletion:(void (^)(double averageBytesPerSecond))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFTimeInterval total = 0.0;
        for(NSInteger i = 0; i < 5; i++)
        {
            total += [self uploadTestFileWithSize:(i+1) * 10000];
        }
        
        safeBlock(completion, total / 5.0);
    });
}

- (CFTimeInterval)downloadTestFileWithNumber:(NSInteger)number
{
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"https://s3.amazonaws.com/liverosaryweb/test%d", (int)number]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    request.timeoutInterval = 10;

    NSURLResponse* response;
    NSError* error;
    CFTimeInterval startInterval = CACurrentMediaTime();
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data != nil && error == nil)
    {
        return (CFTimeInterval)data.length / (CACurrentMediaTime() - startInterval);
    }
    else
    {
        return 0.0;
    }
}

- (void)checkListenBandwidthWithCompletion:(void (^)(double averageBytesPerSecond))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFTimeInterval total = 0.0;
        for(NSInteger i = 0; i < 5; i++)
        {
            total += [self downloadTestFileWithNumber:i + 1];
        }
        
        safeBlock(completion, total / 5.0);
    });
}

#pragma mark - AFURLResponseSerialization

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
