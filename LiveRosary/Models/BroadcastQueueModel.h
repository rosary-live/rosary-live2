//
//  BroadcastQueueModel.h
//  LiveRosary
//
//  Created by Richard Taylor on 3/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^EventReceive)(NSArray* events);

@interface BroadcastQueueModel : NSObject

+ (instancetype)sharedInstance;

- (void)startReceivingForBroadcastId:(NSString*)bid asBroadcaster:(BOOL)asBroadcaster event:(EventReceive)event;
- (void)stopReceiving;

- (void)sendEnterForBroadcastId:(NSString*)bid toUserWithEmail:(NSString*)email withDictionary:(NSDictionary*)dictionary;
- (void)sendUpdateForBroadcastId:(NSString*)bid toUserWithEmail:(NSString*)email withDictionary:(NSDictionary*)dictionary;
- (void)sendExitForBroadcastId:(NSString*)bid toUserWithEmail:(NSString*)email withDictionary:(NSDictionary*)dictionary;

@end
