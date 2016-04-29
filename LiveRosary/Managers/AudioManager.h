//
//  AudioManager.h
//  LiveRosary
//
//  Created by richardtaylor on 1/19/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioManagerDelegate <NSObject>

@optional
- (void)capturedAudioFile:(NSString*)filename sequence:(NSInteger)sequence secondsOfAudio:(double)seconds lastFile:(BOOL)lastFile;
- (void)playedAudioFile:(NSString*)filename sequence:(NSInteger)sequence lastFile:(BOOL)lastFile;
- (void)playPosition:(NSTimeInterval)seconds;
- (void)audioError:(NSError*)error;
- (void)playBufferUnderrun;

@end

@interface AudioManager : NSObject

@property (nonatomic, weak) id<AudioManagerDelegate> delegate;
@property (nonatomic) double sampleRate;
@property (nonatomic) NSInteger channels;
@property (nonatomic) NSInteger secondsPerSegment;
@property (nonatomic, readonly, getter=isRecording) BOOL recording;
@property (nonatomic, readonly, getter=isPlaying) BOOL playing;
@property (nonatomic, readonly, getter=isPreparedToPlay) BOOL preparedToPlay;
@property (nonatomic, readonly) NSInteger playBufferCount;

+ (instancetype)sharedManager;

- (void)startRecording:(NSString*)broadcastId;
- (void)stopRecording;

- (void)prepareToPlay;
- (void)startPlaying;
- (void)stopPlaying;
- (void)addAudioFileToPlay:(NSString*)filename sequence:(NSInteger)sequence lastFile:(BOOL)lastFile;

- (void)inputAveragePowerLevel:(Float32*)averagePower peakHoldLevel:(Float32*)peakLevel;
- (void)outputAveragePowerLevel:(Float32*)averagePower peakHoldLevel:(Float32*)peakLevel;

@end
