//
//  TransferManager.h
//  LiveRosary
//
//  Created by richardtaylor on 1/21/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TransferManager : NSObject

@property (nonatomic, readonly, getter=isSending) BOOL sending;
@property (nonatomic, strong, readonly) NSString* broadcastId;
@property (nonatomic, readonly) NSInteger sequence;

+ (instancetype)sharedManager;

- (void)startSending:(NSString*)broadcastId;
- (void)stopSending;

- (void)addSequenceData:(NSData*)data;

@end
