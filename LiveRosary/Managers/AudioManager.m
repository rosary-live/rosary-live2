//
//  AudioManager.m
//  LiveRosary
//
//  Created by richardtaylor on 1/19/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "AudioManager.h"
#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>

static Boolean IsAACEncoderAvailable(void)
{
    Boolean isAvailable = false;
    
    // get an array of AudioClassDescriptions for all installed encoders for the given format
    // the specifier is the format that we are interested in - this is 'aac ' in our case
    UInt32 encoderSpecifier = kAudioFormatMPEG4AAC;
    UInt32 size;
    
    OSStatus result = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size);
    if (result) { printf("AudioFormatGetPropertyInfo kAudioFormatProperty_Encoders result %lu %4.4s\n", result, (char*)&result); return false; }
    
    UInt32 numEncoders = size / sizeof(AudioClassDescription);
    AudioClassDescription encoderDescriptions[numEncoders];
    
    result = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size, encoderDescriptions);
    if (result) { printf("AudioFormatGetProperty kAudioFormatProperty_Encoders result %lu %4.4s\n", result, (char*)&result); return false; }
    
    printf("Number of AAC encoders available: %lu\n", numEncoders);
    
    // with iOS 7.0 AAC software encode is always available
    // older devices like the iPhone 4s also have a slower/less flexible hardware encoded for supporting AAC encode on older systems
    // newer devices may not have a hardware AAC encoder at all but a faster more flexible software AAC encoder
    // as long as one of these encoders is present we can convert to AAC
    // if both are available you may choose to which one to prefer via the AudioConverterNewSpecific() API
    for (UInt32 i=0; i < numEncoders; ++i) {
        if (encoderDescriptions[i].mSubType == kAudioFormatMPEG4AAC && encoderDescriptions[i].mManufacturer == kAppleHardwareAudioCodecManufacturer) {
            printf("Hardware encoder available\n");
            isAvailable = true;
        }
        if (encoderDescriptions[i].mSubType == kAudioFormatMPEG4AAC && encoderDescriptions[i].mManufacturer == kAppleSoftwareAudioCodecManufacturer) {
            printf("Software encoder available\n");
            isAvailable = true;
        }
    }
    
    return isAvailable;
}

@interface BufferWrapper : NSObject
@property (nonatomic) AudioBuffer* buffer;
@end

@implementation BufferWrapper
@end


@interface AudioManager()
{
    AudioStreamBasicDescription rawFormat;
    AudioStreamBasicDescription compressedFormat;
    AudioConverterRef compressor;
}

@property (nonatomic, strong) AEAudioController* audioController;
@property (nonatomic, strong) id<AEAudioReceiver> audioReceiver;
@property (nonatomic, strong) NSMutableArray<BufferWrapper*>* encodeQueue;

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
        self.encodeQueue = [NSMutableArray new];
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
    [self initializeAudio];
    
    compressedFormat = [self AACFormat];
    AudioConverterNew(&rawFormat, &compressedFormat, &compressor);
    
    UInt32 canResume = 0;
    UInt32 size = sizeof(canResume);
    OSStatus error = AudioConverterGetProperty(compressor, kAudioConverterPropertyCanResumeFromInterruption, &size, &canResume);
    
    UInt32 outputBitRate;
    UInt32 propSize = sizeof(outputBitRate);
    error = AudioConverterGetProperty(compressor, kAudioConverterEncodeBitRate, &propSize, &outputBitRate);
    
    @weakify(self);
    self.audioReceiver = [AEBlockAudioReceiver audioReceiverWithBlock:^(void *source, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio) {
        DDLogDebug(@"Audio input buffer received frames %d  buffers %d  chan %d  size %d", frames, audio->mNumberBuffers, audio->mBuffers[0].mNumberChannels, audio->mBuffers[0].mDataByteSize);
        
        @strongify(self)
        [self encodeBufferList:audio frames:frames];
        
//        BufferWrapper* wrapper = [BufferWrapper new];
//        wrapper.buffer = &audio->mBuffers[0];
//        [self pushEncodeQueueBuffer:wrapper];
    }];
    
    [self.audioController addInputReceiver:self.audioReceiver];
}

- (void)stopRecording
{
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

- (void)pushEncodeQueueBuffer:(BufferWrapper*)buffer
{
    @synchronized(self.encodeQueue)
    {
        [self.encodeQueue addObject:buffer];
    }
}

- (BufferWrapper*)popEncodeQueueBuffer
{
    BufferWrapper* buffer = nil;
    
    @synchronized(self.encodeQueue)
    {
        if(self.encodeQueue.count > 0)
        {
            buffer = [self.encodeQueue objectAtIndex:0];
            [self.encodeQueue removeObjectAtIndex:0];
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
    //aacFormat.mFormatFlags = kMPEG4Object_AAC_Main;
//    aacFormat.mFramesPerPacket = 1024;
    aacFormat.mChannelsPerFrame = 1;
//    aacFormat.mBitsPerChannel = 0;
//    aacFormat.mBytesPerFrame = 0;
//    aacFormat.mBytesPerPacket = 0;
    
    UInt32 size = sizeof(aacFormat);
    OSStatus err = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &aacFormat);
    
    return aacFormat;
}

static OSStatus audioConverterComplexInputDataProc(AudioConverterRef inAudioConverter,
                                                   UInt32* ioNumberDataPackets,
                                                   AudioBufferList* ioData,
                                                   AudioStreamPacketDescription** outDataPacketDescription,
                                                   void* inUserData){
    ioData = (AudioBufferList*)inUserData;
    return 0;
}

- (void)encodeBufferList:(AudioBufferList*)audio frames:(UInt32)frames
{
//    UInt32 size = sizeof(UInt32);
//    UInt32 maxOutputSize;
//    AudioConverterGetProperty(compressor,
//                              kAudioConverterPropertyMaximumOutputPacketSize,
//                              &size,
//                              &maxOutputSize);
    
    AudioBufferList* outputBufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList));
    
    outputBufferList->mNumberBuffers = 1;
    outputBufferList->mBuffers[0].mNumberChannels = 1;
    outputBufferList->mBuffers[0].mDataByteSize = 32768;
    outputBufferList->mBuffers[0].mData = malloc(outputBufferList->mBuffers[0].mDataByteSize);
    
    UInt32 ioOutputDataPacketSize = 1;
    
    OSStatus err;
    err = AudioConverterFillComplexBuffer(compressor,
                                          audioConverterComplexInputDataProc,
                                          audio,
                                          &ioOutputDataPacketSize,
                                          outputBufferList,
                                          NULL);
    
    if(err)
    {
        DDLogError(@"AudioFormat Convert error %d\n", (int)err);
    }
    else
    {
        if(self.delegate && [self.delegate respondsToSelector:@selector(capturedAudioData:)])
        {
            NSData* data = [NSData dataWithBytes:outputBufferList->mBuffers[0].mData length:outputBufferList->mBuffers[0].mDataByteSize];
            [self.delegate capturedAudioData:data];
        }
    }
}

@end
