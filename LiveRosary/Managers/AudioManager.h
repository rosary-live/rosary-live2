//
//  AudioManager.h
//  LiveRosary
//
//  Created by richardtaylor on 1/19/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioManagerDelegate <NSObject>

- (void)audioError:(NSError*)error;
- (void)capturedAudioData:(NSData*)audio secondsOfAudio:(double)seconds;

@end

@interface AudioManager : NSObject

@property (nonatomic, weak) id<AudioManagerDelegate> delegate;
@property (nonatomic) double sampleRate;
@property (nonatomic) NSInteger channels;
@property (nonatomic, readonly, getter=isRecording) BOOL recording;

+ (instancetype)sharedManager;

- (void)startRecording;
- (void)stopRecording;

- (void)startPlaying;
- (void)stopPlaying;

@end
