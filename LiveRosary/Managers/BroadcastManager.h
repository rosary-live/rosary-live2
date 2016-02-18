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

@interface BroadcastManager : NSObject

@property (nonatomic, readonly) BroadcastState state;
@property (nonatomic, strong, readonly) NSString* broadcastId;

+ (instancetype)sharedManager;

- (NSString*)startBroadcasting;
- (void)stopBroadcasting;

- (void)startPlayingBroadcastWithId:(NSString*)broadcastId atSequence:(NSInteger)sequence;
- (void)stopPlaying;

@end
