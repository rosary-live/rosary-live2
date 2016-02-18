//
//  AudioManager.m
//  LiveRosary
//
//  Created by richardtaylor on 1/19/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "AudioManager.h"
#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>
                            
@interface BufferWrapper : NSObject
@property (nonatomic) NSInteger position;
@property (nonatomic) AudioBufferList* buferList;
@property (nonatomic) UInt32 frames;
@end

@implementation BufferWrapper
@end

@interface AudioManager()
{
    AudioStreamBasicDescription rawFormat;
    AudioStreamBasicDescription compressedFormat;
}

@property (nonatomic, strong) AEAudioController* audioController;

@property (nonatomic, strong) id<AEAudioReceiver> audioReceiver;
@property (nonatomic, strong) NSCondition* compressCondition;
@property (nonatomic, strong) NSMutableArray<BufferWrapper*>* compressQueue;
@property (nonatomic) double secondsPerBuffer;
@property (nonatomic, strong) AEAudioFileWriter* fileWriter;
@property (nonatomic) NSInteger sequence;
@property (nonatomic) NSInteger totalFramesForFile;
@property (nonatomic, strong) NSString* currentFileName;
@property (nonatomic, strong) NSString* broadcastId;

@property (nonatomic, strong) AEBlockChannel* audioPlayChannel;
@property (nonatomic, strong) NSCondition* decompressCondition;
@property (nonatomic, strong) NSMutableArray<NSString*>* decompressQueue;
@property (nonatomic, strong) NSMutableArray<BufferWrapper*>* playQueue;
@property (nonatomic, strong) AEAudioFileLoaderOperation* fileReader;

@end

@implementation AudioManager

+ (instancetype)sharedManager
{
    static AudioManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if(self = [super init])
    {
        self.compressCondition = [NSCondition new];
        self.compressQueue = [NSMutableArray new];
        self.decompressCondition = [NSCondition new];
        self.decompressQueue = [NSMutableArray new];
        self.playQueue = [NSMutableArray new];
    }
    return self;
}

- (NSInteger)playBufferCount
{
    return self.playQueue.count;
}

- (void)initializeAudio:(BOOL)record
{
    rawFormat = AEAudioStreamBasicDescriptionMake(AEAudioStreamBasicDescriptionSampleTypeInt16, NO, (int)self.channels, self.sampleRate);
    compressedFormat = [self AACFormat];
    self.audioController = [[AEAudioController alloc] initWithAudioDescription:rawFormat inputEnabled:record];
    
    NSError *error = NULL;
    if(![self.audioController start:&error])
    {
        DDLogError(@"Error starting audio engine: %@", error);
        if(self.delegate && [self.delegate respondsToSelector:@selector(audioError:)])
        {
            [self.delegate audioError:error];
        }
    }
}

- (void)stopAudio
{
    [self.audioController stop];
    self.audioController = nil;
}

- (void)startRecording:(NSString*)broadcastId
{
    if(self.isRecording) return;
    
    [self initializeAudio:YES];
    
    self.broadcastId = broadcastId;
    self.sequence = 1;
    [self startNewRecordFile];
    
    _recording = YES;
    [self performSelectorInBackground:@selector(compressThread) withObject:nil];
    
    @weakify(self);
    self.audioReceiver = [AEBlockAudioReceiver audioReceiverWithBlock:^(void *source, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio) {
        @strongify(self)

        if(self.recording)
        {
            self.secondsPerBuffer = (double)frames / self.sampleRate;
            BufferWrapper* wrapper = [BufferWrapper new];
            wrapper.buferList = audio;
            wrapper.frames = frames;
            [self pushCompressQueueBuffer:wrapper];
        }
    }];
    
    [self.audioController addInputReceiver:self.audioReceiver];
}

- (void)startNewRecordFile
{
    self.totalFramesForFile = 0;
    self.fileWriter = [[AEAudioFileWriter alloc] initWithAudioDescription:rawFormat];
    self.currentFileName = [NSString filenameForBroadcastId:self.broadcastId andSequence:self.sequence];
    [self.fileWriter beginWritingToFileAtPath:self.currentFileName fileType:kAudioFileM4AType error:nil];
}

- (void)finishRecordFile
{
    [self.fileWriter finishWriting];
    
    if(self.delegate != nil && [self.delegate respondsToSelector:@selector(capturedAudioFile:sequence:secondsOfAudio:lastFile:)])
    {
        DDLogDebug(@"Completed file %@", self.currentFileName);
        [self.delegate capturedAudioFile:self.currentFileName sequence:self.sequence secondsOfAudio:10 lastFile:!self.isRecording];
    }
    
    ++_sequence;
}

- (void)stopRecording
{
    if(!self.isRecording) return;

    _recording = NO;
    [self.compressCondition lock];
    [self.compressCondition broadcast];
    [self.compressCondition unlock];
    
    [self stopAudio];
}

- (void)prepareToPlay
{
    if(self.isPreparedToPlay) return;
    
    [self initializeAudio:NO];
    
    _preparedToPlay = YES;
    
    [self performSelectorInBackground:@selector(decompressThread) withObject:nil];
}

- (void)startPlaying
{
    if(!self.isPreparedToPlay) return;
    if(self.isPlaying) return;
    
    _playing = YES;
    self.audioPlayChannel = [AEBlockChannel channelWithBlock:^(const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio) {
        BufferWrapper* buffer = nil;// = [self popPlayQueueBuffer];
        @synchronized(self.playQueue)
        {
            buffer = [self.playQueue objectAtIndex:0];
        }
        
        if(buffer != nil)
        {
            UInt32 sizeInBytes = (UInt32)MIN(frames * 2, buffer.buferList->mBuffers[0].mDataByteSize - buffer.position);
            audio->mBuffers[0].mData = &buffer.buferList->mBuffers[0].mData[buffer.position];
            audio->mBuffers[0].mDataByteSize = sizeInBytes;
            buffer.position += sizeInBytes;
            if(buffer.position >= buffer.buferList->mBuffers[0].mDataByteSize)
            {
                DDLogDebug(@"Popping buffer with length %d", (int)buffer.buferList->mBuffers[0].mDataByteSize);
                [self popPlayQueueBuffer];
            }
        }
    }];

    [self.audioController addChannels:@[self.audioPlayChannel]];
}

- (void)stopPlaying
{
    if(!self.isPlaying) return;
    
    _preparedToPlay = NO;
    _playing = NO;
    
    [self.decompressCondition lock];
    [self.decompressCondition broadcast];
    [self.decompressCondition unlock];
    
    [self.audioController removeChannels:@[self.audioPlayChannel]];
    [self stopAudio];
}

- (void)addAudioFileToPlay:(NSString*)filename
{
    [self pushDecompressQueueBuffer:filename];
}

- (void)pushCompressQueueBuffer:(BufferWrapper*)buffer
{
    [self.compressCondition lock];
    
    @synchronized(self.compressQueue)
    {
        [self.compressQueue addObject:buffer];
    }
    
    [self.compressCondition broadcast];
    [self.compressCondition unlock];
}

- (BufferWrapper*)popCompressQueueBuffer
{
    BufferWrapper* buffer = nil;
    
    @synchronized(self.compressQueue)
    {
        if(self.compressQueue.count > 0)
        {
            buffer = [self.compressQueue objectAtIndex:0];
            [self.compressQueue removeObjectAtIndex:0];
        }
    }
    
    return buffer;
}

- (void)pushDecompressQueueBuffer:(NSString*)file
{
    [self.decompressCondition lock];
    
    @synchronized(self.decompressQueue)
    {
        [self.decompressQueue addObject:file];
    }
    
    [self.decompressCondition broadcast];
    [self.decompressCondition unlock];
}

- (NSString*)popDecompressQueueBuffer
{
    NSString* filename = nil;
    
    @synchronized(self.decompressQueue)
    {
        if(self.decompressQueue.count > 0)
        {
            filename = [self.decompressQueue objectAtIndex:0];
            [self.decompressQueue removeObjectAtIndex:0];
        }
    }
    
    return filename;
}

- (void)pushPlayQueueBuffer:(BufferWrapper*)buffer
{
    @synchronized(self.playQueue)
    {
        [self.playQueue addObject:buffer];
    }
}

- (BufferWrapper*)popPlayQueueBuffer
{
    BufferWrapper* buffer = nil;
    
    @synchronized(self.playQueue)
    {
        if(self.playQueue.count > 0)
        {
            buffer = [self.playQueue objectAtIndex:0];
            [self.playQueue removeObjectAtIndex:0];
        }
    }
    
    return buffer;
}


#pragma mark - Compression

- (void)compressThread
{
    DDLogInfo(@"Compression thread starting");
    
    while(self.isRecording)
    {
        [self.compressCondition lock];
        if(self.compressQueue.count == 0)
        {
            [self.compressCondition wait];
        }
        
        if(self.isRecording)
        {
            BufferWrapper* buffer = [self popCompressQueueBuffer];
            if(buffer != nil)
            {
                AEAudioFileWriterAddAudioSynchronously(self.fileWriter, buffer.buferList, buffer.frames);
                self.totalFramesForFile += buffer.frames;
                double totalSecondsForFile = (double)self.totalFramesForFile / self.sampleRate;
                
                if(totalSecondsForFile >= 10)
                {
                    [self finishRecordFile];
                    [self startNewRecordFile];
                }
            }
        }
        else
        {
            [self finishRecordFile];
        }
        
        [self.compressCondition unlock];
    }
    
    DDLogInfo(@"Compression thread stopping");

}

#pragma mark - Decompression
- (void)decompressThread
{
    DDLogInfo(@"Decompression thread starting");
    
    while(self.isPreparedToPlay || self.isPlaying)
    {
        [self.decompressCondition lock];
        if(self.decompressQueue.count == 0)
        {
            [self.decompressCondition wait];
        }
        
        NSString* filename = nil;
        
        if(self.isPlaying)
        {
            filename = [self popDecompressQueueBuffer];
        }
        
        [self.decompressCondition unlock];

        if(filename != nil)
        {
            DDLogDebug(@"Decompressing file %@", filename);
            self.fileReader = [[AEAudioFileLoaderOperation alloc] initWithFileURL:[NSURL fileURLWithPath:filename] targetAudioDescription:rawFormat];
            
            @weakify(self);
            self.fileReader.completedBlock = ^() {
                @strongify(self);
                
                BufferWrapper* wrapper = [BufferWrapper new];
                wrapper.position = 0;
                wrapper.buferList = self.fileReader.bufferList;
                wrapper.frames = self.fileReader.lengthInFrames;
                [self pushPlayQueueBuffer:wrapper];
            };
            
            [self.fileReader start];
        }
    }
    
    DDLogInfo(@"Decompression thread stopping");
}

- (void)inputAveragePowerLevel:(Float32*)averagePower peakHoldLevel:(Float32*)peakLevel
{
    [self.audioController inputAveragePowerLevel:averagePower peakHoldLevel:peakLevel];
}

- (void)outputAveragePowerLevel:(Float32*)averagePower peakHoldLevel:(Float32*)peakLevel
{
    [self.audioController outputAveragePowerLevel:averagePower peakHoldLevel:peakLevel];
}

#pragma mark - Utilities

- (AudioStreamBasicDescription)AACFormat
{
    AudioStreamBasicDescription aacFormat;
    memset(&aacFormat, 0, sizeof(aacFormat));
    aacFormat.mSampleRate = self.sampleRate;
    aacFormat.mFormatID = kAudioFormatMPEG4AAC;
    aacFormat.mChannelsPerFrame = 1;
    
    UInt32 size = sizeof(aacFormat);
    AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &aacFormat);
    
    return aacFormat;
}

@end
