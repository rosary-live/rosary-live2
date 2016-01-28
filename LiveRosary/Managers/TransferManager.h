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
//- (void)receivedData:(NSData*)data forSequence:(NSInteger)sequence;
//- (void)sendError:(NSError*)error;
//- (void)receiveError:(NSError*)error;

- (void)receivedFile:(NSString*)filename forSequence:(NSInteger)sequence;

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
//- (void)addSequenceData:(NSData*)data;
- (void)addSequenceFile:(NSString*)filename;

- (void)startReceiving:(NSString*)broadcastId atSequence:(NSInteger)sequence;
- (void)stopReceiving;

@end
