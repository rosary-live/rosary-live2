//
//  BroadcastManager.m
//  LiveRosary
//
//  Created by richardtaylor on 1/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "BroadcastManager.h"
#import "AudioManager.h"
#import "TransferManager.h"
#import "NSString+Utilities.h"

@interface BroadcastManager () <AudioManagerDelegate, TransferManagerDelegate>

@property (nonatomic) NSInteger startSequence;

@end


@implementation BroadcastManager

+ (instancetype)sharedManager
{
    static BroadcastManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSString*)startBroadcasting
{
    if(self.state == BroadcastStateIdle)
    {
        _state = BroadcastStateBroadcasting;
        _broadcastId = [NSString UUID];
        
        [TransferManager sharedManager].delegate = self;
        [[TransferManager sharedManager] startSending:self.broadcastId];
        NSString* filename = [NSString filenameForBroadcastId:self.broadcastId andSequence:0];
        [[self infoDataForBroadcastId:self.broadcastId] writeToFile:filename atomically:NO];
        [[TransferManager sharedManager] addSequenceFile:filename lastFile:NO];
        
        [AudioManager sharedManager].delegate = self;
        [AudioManager sharedManager].sampleRate = 11025.0;
        [AudioManager sharedManager].channels = 1;
        [[AudioManager sharedManager] startRecording:self.broadcastId];
        
        return self.broadcastId;
    }
    else
    {
        return nil;
    }
}

- (void)stopBroadcasting
{
    if(self.state == BroadcastStateBroadcasting)
    {
        [[AudioManager sharedManager] stopRecording];
    }
}

- (void)startPlayingBroadcastWithId:(NSString*)broadcastId atSequence:(NSInteger)sequence
{
    if(self.state == BroadcastStateIdle)
    {
        _state = BroadcastStatePlaying;
        _startSequence = sequence;
        
        [AudioManager sharedManager].delegate = self;
        [AudioManager sharedManager].sampleRate = 11025.0;
        [AudioManager sharedManager].channels = 1;
        [TransferManager sharedManager].delegate = self;
        [[TransferManager sharedManager] startReceiving:broadcastId atSequence:sequence];
        
        [[AudioManager sharedManager] prepareToPlay];
    }
}

- (void)stopPlaying
{
    if(self.state == BroadcastStatePlaying)
    {
        [[AudioManager sharedManager] stopPlaying];
        [[TransferManager sharedManager] stopReceiving];
        
        _state = BroadcastStateIdle;
    }
}


- (NSData*)infoDataForBroadcastId:(NSString*)bid
{
    return [NSJSONSerialization dataWithJSONObject:@{
                                                     @"version": @(1),
                                                     @"bid": bid,
                                                     @"start": @((int)[[NSDate date] timeIntervalSince1970]),
                                                     @"language": @"en",
                                                     @"user": @"richard@softwarelogix.com",
                                                     @"name": @"Richard Taylor",
                                                     @"avatar": @"URL",
                                                     @"lat": @"1.2",
                                                     @"lon": @"3.4",
                                                     @"city": @"Olathe",
                                                     @"state": @"KS",
                                                     @"country": @"US",
                                                     @"rate": @(11025),
                                                     @"bits": @(8),
                                                     @"channels": @(1),
                                                     @"compression": @"ACC",
                                                     @"segment_duration": @(10000)
                                                     }
                                           options:0 error:nil];
}

#pragma mark - AudioManagerDelegate

- (void)capturedAudioFile:(NSString*)filename sequence:(NSInteger)sequence secondsOfAudio:(double)seconds lastFile:(BOOL)lastFile
{
    [[TransferManager sharedManager] addSequenceFile:filename lastFile:lastFile];
    DDLogDebug(@"Added file to send: %@", filename);
}


#pragma mark - TransferManagerDelegate

- (void)receivedFile:(NSString*)filename forSequence:(NSInteger)sequence
{
    [[AudioManager sharedManager] addAudioFileToPlay:filename];
    
    if(![AudioManager sharedManager].isPlaying && sequence > self.startSequence)
    {
        [[AudioManager sharedManager] startPlaying];
    }
}

- (void)sentFile:(NSString*)filename forSequence:(NSInteger)sequence lastFile:(BOOL)lastFile
{
    if(lastFile)
    {
        DDLogInfo(@"Send last file");
        [[TransferManager sharedManager] stopSending];
        _state = BroadcastStateIdle;
    }
}

- (void)sendError:(NSError*)error forFile:(NSString*)filename sequence:(NSInteger)sequence
{
}

@end
