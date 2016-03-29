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

- (void)startReceivingForBroadcastId:(NSString*)bid event:(EventReceive)event;
- (void)stopReceiving;

- (void)sendEnterForBroadcastId:(NSString*)bid withDictionary:(NSDictionary*)dictionary;
- (void)sendExitForBroadcastId:(NSString*)bid withDictionary:(NSDictionary*)dictionary;

@end
