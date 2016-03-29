//
//  BroadcastQueueModel.m
//  LiveRosary
//
//  Created by Richard Taylor on 3/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "BroadcastQueueModel.h"
#import <AWSSQS/AWSSQS.h>
#import "UserManager.h"

NSString * const kBroadcastQueueURL = @"https://sqs.us-east-1.amazonaws.com/767603916237/broadcast";

@interface BroadcastQueueModel ()

@property (nonatomic, strong) AWSSQS* sqs;
@property (nonatomic, strong) NSString* receiveBroadcastId;
@property (nonatomic, strong) EventReceive eventRecieveBlock;

@end

@implementation BroadcastQueueModel

+ (instancetype)sharedInstance
{
    static BroadcastQueueModel* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if(self != nil)
    {
        AWSServiceConfiguration* configuration = [UserManager sharedManager].configuration;
        
        [AWSSQS registerSQSWithConfiguration:configuration forKey:@"SQS"];
        self.sqs = [AWSSQS SQSForKey:@"SQS"];
    }
    
    return self;
}

- (void)startReceivingForBroadcastId:(NSString*)bid event:(EventReceive)event
{
    self.receiveBroadcastId = bid;
    self.eventRecieveBlock = event;
    [self performSelectorInBackground:@selector(eventReceiveThread) withObject:nil];

}

- (void)stopReceiving
{
    self.eventRecieveBlock = nil;
}

- (void)eventReceiveThread
{
    DDLogInfo(@"eventReceiveThread starting");
    
    while(self.eventRecieveBlock != nil)
    {
        AWSSQSReceiveMessageRequest* req = [AWSSQSReceiveMessageRequest new];
        req.queueUrl = kBroadcastQueueURL;
        req.visibilityTimeout = @(1);
        req.waitTimeSeconds = @(20);
        req.maxNumberOfMessages = @(10);
        [[[self.sqs receiveMessage:req] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
            if(task.error != nil)
            {
                DDLogError(@"SQS receive error: %@", task.error);
            }
            else if(task.exception != nil)
            {
                DDLogError(@"SQS receive exception: %@", task.exception);
            }
            else if(task.result != nil && [task.result isKindOfClass:[AWSSQSReceiveMessageResult class]])
            {
                AWSSQSReceiveMessageResult* messages = (AWSSQSReceiveMessageResult*)[task result];
                if(messages.messages != nil)
                {
                    NSMutableArray* messagesForReceiver = [NSMutableArray new];
                    
                    for(AWSSQSMessage* message in messages.messages)
                    {
                        NSData* data = [message.body dataUsingEncoding:NSUTF8StringEncoding];
                        NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                        if([self.receiveBroadcastId isEqualToString:dict[@"bid"]])
                        {
                            [messagesForReceiver addObject:dict];
                            
                            AWSSQSDeleteMessageRequest* deleteReq = [AWSSQSDeleteMessageRequest new];
                            deleteReq.queueUrl = kBroadcastQueueURL;
                            deleteReq.receiptHandle = message.receiptHandle;
                            [[self.sqs deleteMessage:deleteReq] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
                                if(task.error != nil)
                                {
                                    NSLog(@"error deleting message: %@", task.error);
                                }
                                else if(task.exception != nil)
                                {
                                    NSLog(@"exception deleting message: %@", task.exception);
                                }
                                else if(task.result)
                                {
                                    DDLogDebug(@"message deleted");
                                }
                                
                                return [AWSTask taskWithResult:nil];
                            }];
                        }
                    }
                                        
                    if(messagesForReceiver.count > 0)
                    {
                        self.eventRecieveBlock(messagesForReceiver);
                    }
                }
            }
            
            return [AWSTask taskWithResult:nil];
        }] waitUntilFinished];
    }
    
    DDLogInfo(@"eventReceiveThread stopping");
}

- (void)sendEnterForBroadcastId:(NSString*)bid withDictionary:(NSDictionary*)dictionary
{
    NSDictionary* messageDict = @{
                                  @"type": @"enter",
                                  @"bid": bid,
                                  @"event": dictionary
                                  };
    
    [self sendMessage:messageDict];
}

- (void)sendUpdateForBroadcastId:(NSString*)bid withDictionary:(NSDictionary*)dictionary
{
    NSDictionary* messageDict = @{
                                  @"type": @"update",
                                  @"bid": bid,
                                  @"event": dictionary
                                  };
    
    [self sendMessage:messageDict];
}

- (void)sendExitForBroadcastId:(NSString*)bid withDictionary:(NSDictionary*)dictionary
{
    NSDictionary* messageDict = @{
                                  @"type": @"exit",
                                  @"bid": bid,
                                  @"event": dictionary
                                  };
    
    [self sendMessage:messageDict];
}

- (void)sendMessage:(NSDictionary*)dictionary
{
    AWSSQSSendMessageRequest* req = [AWSSQSSendMessageRequest new];
    req.queueUrl = kBroadcastQueueURL;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    req.messageBody = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    req.delaySeconds = 0;
    [[self.sqs sendMessage:req] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        if(task.error)
        {
            DDLogError(@"Message send error: %@", task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Message send exception: %@", task.exception);
        }
        else if(task.result)
        {
            DDLogInfo(@"Message sent");
        }
        
        return [AWSTask taskWithResult:nil];
    }];
}

@end
