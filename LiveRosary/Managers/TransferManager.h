//
//  TransferManager.h
//  LiveRosary
//
//  Created by richardtaylor on 1/21/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TransferManagerDelegate <NSObject>

@optional
- (void)receivedFile:(NSString*)filename forSequence:(NSInteger)sequence lastFile:(BOOL)lastFile;
- (void)sentFile:(NSString*)filename forSequence:(NSInteger)sequence lastFile:(BOOL)lastFile;
- (void)sendError:(NSError*)error forFile:(NSString*)filename sequence:(NSInteger)sequence;

@end

@interface TransferManager : NSObject

@property (nonatomic, weak) id<TransferManagerDelegate> delegate;
@property (nonatomic, readonly, getter=isSending) BOOL sending;
@property (nonatomic, readonly, getter=isReceiving) BOOL receiving;
@property (nonatomic, strong, readonly) NSString* broadcastId;
@property (nonatomic, readonly) NSInteger sequence;

+ (instancetype)sharedManager;

- (void)startSending:(NSString*)broadcastId;
- (void)stopSending;
- (void)addSequenceFile:(NSString*)filename lastFile:(BOOL)lastFile;

- (void)startReceiving:(NSString*)broadcastId atSequence:(NSInteger)sequence;
- (void)stopReceiving;

- (void)checkBroadcastBandwidthWithCompletion:(void (^)(double averageBytesPerSecond))completion;
- (void)checkListenBandwidthWithCompletion:(void (^)(double averageBytesPerSecond))completion;

@end
