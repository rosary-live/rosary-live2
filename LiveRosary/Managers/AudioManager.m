//
//  AudioManager.m
//  LiveRosary
//
//  Created by richardtaylor on 1/19/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "AudioManager.h"
#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>


static OSStatus handleCompressBuffer(AudioConverterRef inAudioConverter,
                                    UInt32* ioNumberDataPackets,
                                    AudioBufferList* ioData,
                                    AudioStreamPacketDescription** outDataPacketDescription,
                                    void* inUserData);

static OSStatus handleDecompressBuffer(AudioConverterRef inAudioConverter,
                                         UInt32* ioNumberDataPackets,
                                         AudioBufferList* ioData,
                                         AudioStreamPacketDescription** outDataPacketDescription,
                                         void* inUserData);

static Boolean IsAACEncoderAvailable(void);


@interface AudioManager()
{
    AudioStreamBasicDescription rawFormat;
    AudioStreamBasicDescription compressedFormat;
    AudioConverterRef compressor;
}

@property (nonatomic, strong) AEAudioController* audioController;
@property (nonatomic, strong) id<AEAudioReceiver> audioReceiver;
@property (nonatomic, strong) NSCondition* compressCondition;
@property (nonatomic, strong) NSMutableArray<NSMutableData*>* compressQueue;
@property (nonatomic) double secondsPerBuffer;

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
    }
    return self;
}

- (void)initializeAudio
{
    IsAACEncoderAvailable();
    
    rawFormat = AEAudioStreamBasicDescriptionMake(AEAudioStreamBasicDescriptionSampleTypeInt16, NO, (int)self.channels, self.sampleRate);
    self.audioController = [[AEAudioController alloc] initWithAudioDescription:rawFormat inputEnabled:YES];
    
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

- (void)startRecording
{
    if(self.isRecording) return;
    
    [self initializeAudio];
    
    compressedFormat = [self AACFormat];
    AudioConverterNew(&rawFormat, &compressedFormat, &compressor);
    
    UInt32 canResume = 0;
    UInt32 size = sizeof(canResume);
    OSStatus error = AudioConverterGetProperty(compressor, kAudioConverterPropertyCanResumeFromInterruption, &size, &canResume);
    
    UInt32 outputBitRate;
    UInt32 propSize = sizeof(outputBitRate);
    error = AudioConverterGetProperty(compressor, kAudioConverterEncodeBitRate, &propSize, &outputBitRate);
    
    _recording = YES;
    [self performSelectorInBackground:@selector(compressThread) withObject:nil];
    
    @weakify(self);
    self.audioReceiver = [AEBlockAudioReceiver audioReceiverWithBlock:^(void *source, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio) {
        //DDLogDebug(@"Audio input buffer received frames %d  buffers %d  chan %d  size %d", frames, audio->mNumberBuffers, audio->mBuffers[0].mNumberChannels, audio->mBuffers[0].mDataByteSize);
        
        self.secondsPerBuffer = (double)frames / self.sampleRate;
        @strongify(self)
        NSMutableData* buffer = [NSMutableData dataWithBytes:audio->mBuffers[0].mData length:audio->mBuffers[0].mDataByteSize];
        [self pushCompressQueueBuffer:buffer];
    }];
    
    [self.audioController addInputReceiver:self.audioReceiver];
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

- (void)startPlaying
{
    [self initializeAudio];
}
    
- (void)stopPlaying
{
    [self stopAudio];
}

- (void)pushCompressQueueBuffer:(NSMutableData*)buffer
{
    [self.compressCondition lock];
    
    @synchronized(self.compressQueue)
    {
        [self.compressQueue addObject:buffer];
    }
    
    [self.compressCondition broadcast];
    [self.compressCondition unlock];
}

- (NSMutableData*)popCompressQueueBuffer
{
    NSMutableData* buffer = nil;
    
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

- (void)compressThread
{
    DDLogInfo(@"Compression thread starting");
    
    char* convertBuffer = malloc(32 * 1024);
    while(self.isRecording)
    {
        AudioBufferList outAudioBufferList;
        outAudioBufferList.mNumberBuffers = 1;
        outAudioBufferList.mBuffers[0].mNumberChannels = 1;
        outAudioBufferList.mBuffers[0].mDataByteSize = 32 * 1024;
        outAudioBufferList.mBuffers[0].mData = convertBuffer;
        
        UInt32 ioOutputDataPacketSize = 1;
        
        const OSStatus conversionResult = AudioConverterFillComplexBuffer(compressor, handleCompressBuffer, (__bridge void*)self, &ioOutputDataPacketSize, &outAudioBufferList, NULL);
        
        if(conversionResult == 0)
        {
            @synchronized(self.compressQueue)
            {
                if(self.compressQueue.count > 0)
                {
                    [self.compressQueue removeObjectAtIndex:0];
                }
            }
            
            //[self.readyToSendBuffer appendBytes:outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
            //NSLog(@"conveted %d %d", outAudioBufferList.mBuffers[0].mDataByteSize, (int)self.readyToSendBuffer.length);
            
            if(self.delegate && [self.delegate respondsToSelector:@selector(capturedAudioData:secondsOfAudio:)])
            {
                NSData* buffer = [NSData dataWithBytes:outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
                [self.delegate capturedAudioData:buffer secondsOfAudio:self.secondsPerBuffer];
            }
        }
        else
        {
            if(self.isRecording)
            {
                DDLogError(@"Compress error %d", (int)conversionResult);
            }
        }
    }
    
    DDLogInfo(@"Compression thread stopping");

}

- (OSStatus)handleCompressBuffer:(UInt32*)ioNumberDataPackets data:(AudioBufferList*)ioData description:(AudioStreamPacketDescription**)outDataPacketDescription
{
    OSStatus status = noErr;
    
    [self.compressCondition lock];
    
    if(self.compressQueue.count == 0)
    {
        [self.compressCondition wait];
    }
    
    if(self.isRecording)
    {
        NSMutableData* buffer;
        @synchronized(self.compressQueue)
        {
            buffer = [self.compressQueue firstObject];
        }
        
        ioData->mNumberBuffers = 1;
        ioData->mBuffers[0].mNumberChannels = 1;
        ioData->mBuffers[0].mDataByteSize = (UInt32)buffer.length;
        ioData->mBuffers[0].mData = [buffer mutableBytes];
        
        *ioNumberDataPackets = ioData->mBuffers[0].mDataByteSize / 2;
    }
    else
    {
        ioData->mBuffers[0].mDataByteSize = 0;
        *ioNumberDataPackets = 0;
        status = -1;
    }
    
    [self.compressCondition unlock];
    
    return status;
}


static OSStatus handleCompressBuffer(AudioConverterRef inAudioConverter,
                                     UInt32* ioNumberDataPackets,
                                     AudioBufferList* ioData,
                                     AudioStreamPacketDescription** outDataPacketDescription,
                                     void* inUserData)
{
    AudioManager* manager = (__bridge AudioManager*)inUserData;
    return [manager handleCompressBuffer:ioNumberDataPackets data:ioData description:outDataPacketDescription];
}

static OSStatus handleDecompressBuffer(AudioConverterRef inAudioConverter,
                                       UInt32* ioNumberDataPackets,
                                       AudioBufferList* ioData,
                                       AudioStreamPacketDescription** outDataPacketDescription,
                                       void* inUserData)
{
    return noErr;
}

static Boolean IsAACEncoderAvailable(void)
{
    Boolean isAvailable = false;
    
    // get an array of AudioClassDescriptions for all installed encoders for the given format
    // the specifier is the format that we are interested in - this is 'aac ' in our case
    UInt32 encoderSpecifier = kAudioFormatMPEG4AAC;
    UInt32 size;
    
    OSStatus result = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size);
    if(result) { DDLogInfo(@"AudioFormatGetPropertyInfo kAudioFormatProperty_Encoders result %d %4.4s", (int)result, (char*)&result); return false; }
    
    UInt32 numEncoders = size / sizeof(AudioClassDescription);
    AudioClassDescription encoderDescriptions[numEncoders];
    
    result = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size, encoderDescriptions);
    if(result) { DDLogInfo(@"AudioFormatGetProperty kAudioFormatProperty_Encoders result %d %4.4s", (int)result, (char*)&result); return false; }
    
    DDLogInfo(@"Number of AAC encoders available: %d\n", (int)numEncoders);
    
    // with iOS 7.0 AAC software encode is always available
    // older devices like the iPhone 4s also have a slower/less flexible hardware encoded for supporting AAC encode on older systems
    // newer devices may not have a hardware AAC encoder at all but a faster more flexible software AAC encoder
    // as long as one of these encoders is present we can convert to AAC
    // if both are available you may choose to which one to prefer via the AudioConverterNewSpecific() API
    for (UInt32 i=0; i < numEncoders; ++i) {
        if (encoderDescriptions[i].mSubType == kAudioFormatMPEG4AAC && encoderDescriptions[i].mManufacturer == kAppleHardwareAudioCodecManufacturer) {
            DDLogInfo(@"Hardware encoder available");
            isAvailable = true;
        }
        if (encoderDescriptions[i].mSubType == kAudioFormatMPEG4AAC && encoderDescriptions[i].mManufacturer == kAppleSoftwareAudioCodecManufacturer) {
            DDLogInfo(@"Software encoder available");
            isAvailable = true;
        }
    }
    
    return isAvailable;
}

@end
