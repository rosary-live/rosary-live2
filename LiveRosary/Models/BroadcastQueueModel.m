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
#import "LiveRosaryService.h"

NSString * const kBroadcastQueueBaseURL = @"https://sqs.us-east-1.amazonaws.com/767603916237/";

@interface BroadcastQueueModel ()

@property (nonatomic, strong) AWSSQS* sqs;
@property (nonatomic, strong) NSString* receiveBroadcastId;
@property (nonatomic, strong) EventReceive eventRecieveBlock;
@property (nonatomic) BOOL asBroadcaster;

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

- (void)startReceivingForBroadcastId:(NSString*)bid asBroadcaster:(BOOL)asBroadcaster event:(EventReceive)event
{
    self.receiveBroadcastId = bid;
    self.eventRecieveBlock = event;
    self.asBroadcaster = asBroadcaster;
    [self performSelectorInBackground:@selector(eventReceiveThread) withObject:nil];

}

- (void)stopReceiving
{
    self.eventRecieveBlock = nil;
}

- (NSString*)userQueueURL
{
    NSMutableString* email = [[UserManager sharedManager].email mutableCopy];
    
    [email replaceOccurrencesOfString:@"@" withString:@"-" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"." withString:@"-" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"!" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"#" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"$" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"%%" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"&" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"'" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"+" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"*" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"/" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"=" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"?" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"^" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"`" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"{" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"|" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"}" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    [email replaceOccurrencesOfString:@"~" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, email.length)];
    
    return [NSString stringWithFormat:@"%@%@", kBroadcastQueueBaseURL, email];
}

- (void)eventReceiveThread
{
    DDLogInfo(@"eventReceiveThread starting");
    NSString* queueURL = [self userQueueURL];
    
    while(self.eventRecieveBlock != nil)
    {
        AWSSQSReceiveMessageRequest* req = [AWSSQSReceiveMessageRequest new];
        req.queueUrl = queueURL;
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
                    DDLogDebug(@"SQS received: %@", task.result);
                    
                    NSMutableArray* messagesForReceiver = [NSMutableArray new];
                    
                    for(AWSSQSMessage* message in messages.messages)
                    {
                        NSData* data = [message.body dataUsingEncoding:NSUTF8StringEncoding];
                        NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                        if([self.receiveBroadcastId isEqualToString:dict[@"bid"]])
                        {
                            [messagesForReceiver addObject:dict];
                        }
                        
                        AWSSQSDeleteMessageRequest* deleteReq = [AWSSQSDeleteMessageRequest new];
                        deleteReq.queueUrl = queueURL;
                        deleteReq.receiptHandle = message.receiptHandle;
                        [[self.sqs deleteMessage:deleteReq] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
                            if(task.error != nil)
                            {
                                DDLogDebug(@"error deleting message: %@", task.error);
                            }
                            else if(task.exception != nil)
                            {
                                DDLogDebug(@"exception deleting message: %@", task.exception);
                            }
                            else if(task.result)
                            {
                                DDLogDebug(@"message deleted");
                            }
                            
                            return [AWSTask taskWithResult:nil];
                        }];
                    }
                                        
                    if(messagesForReceiver.count > 0)
                    {
                        if(self.eventRecieveBlock != nil) {
                            self.eventRecieveBlock(messagesForReceiver);
                        }
                    }
                }
            }
            
            return [AWSTask taskWithResult:nil];
        }] waitUntilFinished];
    }
    
    DDLogInfo(@"eventReceiveThread stopping");
}

- (void)sendEnterForBroadcastId:(NSString*)bid toUserWithEmail:(NSString*)email withDictionary:(NSDictionary*)dictionary
{
    NSDictionary* messageDict = @{
                                  @"type": @"enter",
                                  @"bid": bid,
                                  @"event": dictionary,
                                  @"noResponse": @(email != nil)
                                  };
    
    if(email != nil)
    {
        [self sendMessage:messageDict toUserWithEmail:email withRetries:3];
    }
    else
    {
        [self sendMessage:messageDict toBroadcastWithId:bid withRetries:3];
    }
}

- (void)sendUpdateForBroadcastId:(NSString*)bid toUserWithEmail:(NSString*)email withDictionary:(NSDictionary*)dictionary
{
    NSDictionary* messageDict = @{
                                  @"type": @"update",
                                  @"bid": bid,
                                  @"event": dictionary
                                  };
    
    if(email != nil)
    {
        [self sendMessage:messageDict toUserWithEmail:email withRetries:3];
    }
    else
    {
        [self sendMessage:messageDict toBroadcastWithId:bid withRetries:3];
    }
}

- (void)sendExitForBroadcastId:(NSString*)bid toUserWithEmail:(NSString*)email withDictionary:(NSDictionary*)dictionary
{
    NSDictionary* messageDict = @{
                                  @"type": @"exit",
                                  @"bid": bid,
                                  @"event": dictionary
                                  };
    
    if(email != nil)
    {
        [self sendMessage:messageDict toUserWithEmail:email withRetries:3];
    }
    else
    {
        [self sendMessage:messageDict toBroadcastWithId:bid withRetries:3];
    }
}

- (void)sendTerminateForBroadcastId:(NSString*)bid
{
    NSDictionary* messageDict = @{
                                  @"type": @"terminate",
                                  @"bid": bid,
                                  @"email": [UserManager sharedManager].email,
                                  @"password": [UserManager sharedManager].password
                                  };
    
    [self sendMessage:messageDict toBroadcastWithId:bid withRetries:3];
}

- (void)sendMessage:(NSDictionary*)dictionary toBroadcastWithId:(NSString*)bid withRetries:(NSInteger)retries
{
    DDLogError(@"sendMessage sending toBroadcast %@", bid);
    [[LiveRosaryService sharedService] sendMessage:dictionary toBroadcast:bid completion:^(NSError *error) {
        if(error != nil) {
            DDLogError(@"sendMessage error toBroadcast %@: %@", bid, error);
            
            if(retries > 0) {
                [self sendMessage:dictionary toBroadcastWithId:bid withRetries:retries - 1];
            }
        } else {
            DDLogError(@"sendMessage sent toBroadcast %@", bid);
        }
    }];
}

- (void)sendMessage:(NSDictionary*)dictionary toUserWithEmail:(NSString*)email withRetries:(NSInteger)retries
{
    DDLogError(@"sendMessage sending toEmail %@", email);
    [[LiveRosaryService sharedService] sendMessage:dictionary toEmail:email completion:^(NSError *error) {
        
        if(error != nil) {
            DDLogError(@"sendMessage error toEmail %@ : %@", email, error);
            
            if(retries > 0) {
                [self sendMessage:dictionary toUserWithEmail:email withRetries:retries - 1];
            }
        } else {
            DDLogError(@"sendMessage sent toEmail %@", email);
        }
    }];
}

@end
