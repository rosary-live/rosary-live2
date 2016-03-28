//
//  BroadcastManager.h
//  LiveRosary
//
//  Created by richardtaylor on 1/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BroadcastState) {
    BroadcastStateIdle,
    BroadcastStateBroadcasting,
    BroadcastStatePlaying,
};

@protocol BroadcastManagerDelegate <NSObject>

- (void)broadcastHasEnded;

@end


@interface BroadcastManager : NSObject

@property (nonatomic, weak) id<BroadcastManagerDelegate> delegate;
@property (nonatomic, readonly) BroadcastState state;
@property (nonatomic, strong, readonly) NSString* broadcastId;

+ (instancetype)sharedManager;

- (void)startBroadcastingWithCompletion:(void (^)(NSString* brodcastId, BOOL insufficientBandwidth))completion;
- (void)stopBroadcasting;

- (void)startPlayingBroadcastWithId:(NSString*)broadcastId atSequence:(NSInteger)sequence completion:(void (^)(BOOL insufficientBandwidth))completion;
- (void)stopPlaying;

@end
