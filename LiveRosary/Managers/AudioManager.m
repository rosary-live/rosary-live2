//
//  AudioManager.m
//  LiveRosary
//
//  Created by richardtaylor on 1/19/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "AudioManager.h"
#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>


//static OSStatus handleCompressBuffer(AudioConverterRef inAudioConverter,
//                                    UInt32* ioNumberDataPackets,
//                                    AudioBufferList* ioData,
//                                    AudioStreamPacketDescription** outDataPacketDescription,
//                                    void* inUserData);
//
//static OSStatus handleDecompressBuffer(AudioConverterRef inAudioConverter,
//                                         UInt32* ioNumberDataPackets,
//                                         AudioBufferList* ioData,
//                                         AudioStreamPacketDescription** outDataPacketDescription,
//                                         void* inUserData);

static Boolean IsAACEncoderAvailable(void);

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
//    AudioConverterRef compressor;
//    AudioConverterRef decompressor;
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

- (void)initializeAudio
{
    IsAACEncoderAvailable();
    
    rawFormat = AEAudioStreamBasicDescriptionMake(AEAudioStreamBasicDescriptionSampleTypeInt16, NO, (int)self.channels, self.sampleRate);
    compressedFormat = [self AACFormat];
    self.audioController = [[AEAudioController alloc] initWithAudioDescription:rawFormat inputEnabled:NO];
    
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
    
//    AudioConverterNew(&rawFormat, &compressedFormat, &compressor);
//    
//    UInt32 canResume = 0;
//    UInt32 size = sizeof(canResume);
//    OSStatus error = AudioConverterGetProperty(compressor, kAudioConverterPropertyCanResumeFromInterruption, &size, &canResume);
//    
//    UInt32 outputBitRate;
//    UInt32 propSize = sizeof(outputBitRate);
//    error = AudioConverterGetProperty(compressor, kAudioConverterEncodeBitRate, &propSize, &outputBitRate);
    
    self.sequence = 1;
    [self startNewRecordFile];
    
    _recording = YES;
    [self performSelectorInBackground:@selector(compressThread) withObject:nil];
    
    @weakify(self);
    self.audioReceiver = [AEBlockAudioReceiver audioReceiverWithBlock:^(void *source, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio) {
        //DDLogDebug(@"Audio input buffer received frames %d  buffers %d  chan %d  size %d", frames, audio->mNumberBuffers, audio->mBuffers[0].mNumberChannels, audio->mBuffers[0].mDataByteSize);
        
        self.secondsPerBuffer = (double)frames / self.sampleRate;
        @strongify(self)
        //NSMutableData* buffer = [NSMutableData dataWithBytes:audio->mBuffers[0].mData length:audio->mBuffers[0].mDataByteSize];
        BufferWrapper* wrapper = [BufferWrapper new];
        wrapper.buferList = audio;
        wrapper.frames = frames;
        [self pushCompressQueueBuffer:wrapper];
    }];
    
    [self.audioController addInputReceiver:self.audioReceiver];
}

- (void)startNewRecordFile
{
    self.totalFramesForFile = 0;
    self.fileWriter = [[AEAudioFileWriter alloc] initWithAudioDescription:rawFormat];
    self.currentFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat: @"%06d", (int)self.sequence]];
    [self.fileWriter beginWritingToFileAtPath:self.currentFileName fileType:kAudioFileM4AType error:nil];
}

- (void)finishRecordFile
{
    [self.fileWriter finishWriting];
    
    if(self.delegate != nil && [self.delegate respondsToSelector:@selector(capturedAudioFile:sequence:secondsOfAudio:)])
    {
        DDLogDebug(@"Completed file %@", self.currentFileName);
        [self.delegate capturedAudioFile:self.currentFileName sequence:self.sequence secondsOfAudio:10];
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
    //AudioConverterDispose(compressor);
}

- (void)prepareToPlay
{
    if(self.isPreparedToPlay) return;
    
    [self initializeAudio];
    
    //AudioConverterNew(&compressedFormat, &rawFormat, &decompressor);
    
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
            //memcpy(audio->mBuffers[0].mData, buffer.buferList->mBuffers[0].mData, sizeInBytes);
            audio->mBuffers[0].mData = &buffer.buferList->mBuffers[0].mData[buffer.position];
            audio->mBuffers[0].mDataByteSize = sizeInBytes;
            buffer.position += sizeInBytes;
            //DDLogDebug(@"Playing %d bytes  new position %d", (int)sizeInBytes, (int)buffer.position);
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
    //AudioConverterDispose(decompressor);
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
    
    //char* convertBuffer = malloc(32 * 1024);
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
                //NSLog(@"Wrote %d frame %d bytes  %d total frames  %g seconds", (int)buffer.frames, (int)buffer.buferList[0].mBuffers->mDataByteSize, (int)self.totalFramesForFile, totalSecondsForFile);
                
                if(totalSecondsForFile >= 10)
                {
                    [self finishRecordFile];
                    [self startNewRecordFile];
                }
            }
        }
        
        [self.compressCondition unlock];
    }
    
    
//        AudioBufferList outAudioBufferList;
//        outAudioBufferList.mNumberBuffers = 1;
//        outAudioBufferList.mBuffers[0].mNumberChannels = 1;
//        outAudioBufferList.mBuffers[0].mDataByteSize = 32 * 1024;
//        outAudioBufferList.mBuffers[0].mData = convertBuffer;
//        
//        UInt32 ioOutputDataPacketSize = 1;
//        
//        const OSStatus conversionResult = AudioConverterFillComplexBuffer(compressor, handleCompressBuffer, (__bridge void*)self, &ioOutputDataPacketSize, &outAudioBufferList, NULL);
//        
//        if(conversionResult == 0)
//        {
//            @synchronized(self.compressQueue)
//            {
//                if(self.compressQueue.count > 0)
//                {
//                    [self.compressQueue removeObjectAtIndex:0];
//                }
//            }
//            
//            if(self.delegate && [self.delegate respondsToSelector:@selector(capturedAudioData:secondsOfAudio:)])
//            {
//                NSData* buffer = [NSData dataWithBytes:outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
//                [self.delegate capturedAudioData:buffer secondsOfAudio:self.secondsPerBuffer];
//            }
//        }
//        else
//        {
//            if(self.isRecording)
//            {
//                DDLogError(@"Compress error %d", (int)conversionResult);
//            }
//        }
//    }
    
    DDLogInfo(@"Compression thread stopping");

}

//- (OSStatus)handleCompressBuffer:(UInt32*)ioNumberDataPackets data:(AudioBufferList*)ioData description:(AudioStreamPacketDescription**)outDataPacketDescription
//{
//    OSStatus status = noErr;
//    
//    [self.compressCondition lock];
//    
//    if(self.compressQueue.count == 0)
//    {
//        [self.compressCondition wait];
//    }
//    
//    if(self.isRecording)
//    {
//        NSMutableData* buffer;
//        @synchronized(self.compressQueue)
//        {
//            buffer = [self.compressQueue firstObject];
//        }
//
//        ioData->mNumberBuffers = 1;
//        ioData->mBuffers[0].mNumberChannels = 1;
//        ioData->mBuffers[0].mDataByteSize = (UInt32)buffer.length;
//        ioData->mBuffers[0].mData = [buffer mutableBytes];
//        
//        *ioNumberDataPackets = ioData->mBuffers[0].mDataByteSize / 2;
//    }
//    else
//    {
//        ioData->mBuffers[0].mDataByteSize = 0;
//        *ioNumberDataPackets = 0;
//        status = -1;
//    }
//    
//    [self.compressCondition unlock];
//    
//    return status;
//}

//static OSStatus handleCompressBuffer(AudioConverterRef inAudioConverter,
//                                     UInt32* ioNumberDataPackets,
//                                     AudioBufferList* ioData,
//                                     AudioStreamPacketDescription** outDataPacketDescription,
//                                     void* inUserData)
//{
//    AudioManager* manager = (__bridge AudioManager*)inUserData;
//    return [manager handleCompressBuffer:ioNumberDataPackets data:ioData description:outDataPacketDescription];
//}

#pragma mark - Decompression
- (void)decompressThread
{
    DDLogInfo(@"Decompression thread starting");
    
    //char* convertBuffer = malloc(32 * 1024);
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
            
//            @weakify(self);
//            self.fileReader.audioReceiverBlock = ^(AudioBufferList *audio, UInt32 lengthInFrames) {
//                @strongify(self);
//                BufferWrapper* wrapper = [BufferWrapper new];
//                wrapper.position = 0;
//                wrapper.buferList = audio;
//                wrapper.frames = lengthInFrames;
//                [self pushPlayQueueBuffer:wrapper];
//            };
            
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
    
        
//        AudioBufferList outAudioBufferList;
//        outAudioBufferList.mNumberBuffers = 1;
//        outAudioBufferList.mBuffers[0].mNumberChannels = 1;
//        outAudioBufferList.mBuffers[0].mDataByteSize = 32 * 1024;
//        outAudioBufferList.mBuffers[0].mData = convertBuffer;
//        
////        AudioStreamPacketDescription* pd = (AudioStreamPacketDescription *)(malloc(50 * sizeof(AudioStreamPacketDescription)));
////        memset(pd, 0xAB, 50 * sizeof(AudioStreamPacketDescription));
//        
//        NSMutableData* buffer = nil;
//        @synchronized(self.decompressQueue)
//        {
//            if(self.decompressQueue.count > 0)
//            {
//                buffer = [self.decompressQueue firstObject];
//            }
//        }
//        
//        if(buffer != nil)
//        {
//            DDLogDebug(@"Decompressing buffer with length %d", (int)buffer.length);
//            
//            UInt32 ioOutputDataPacketSize = 128;
//            
//            AudioStreamPacketDescription* pd = (AudioStreamPacketDescription *)(malloc(sizeof(AudioStreamPacketDescription)));
//            pd->mStartOffset = 0;
//            pd->mVariableFramesInPacket = 0;
//            pd->mDataByteSize = (UInt32)buffer.length;
//            
//            const OSStatus conversionResult = AudioConverterFillComplexBuffer(decompressor, handleDecompressBuffer, (__bridge void*)self, &ioOutputDataPacketSize, &outAudioBufferList, pd);
//            
//            @synchronized(self.decompressQueue)
//            {
//                if(self.decompressQueue.count > 0)
//                {
//                    [self.decompressQueue removeObjectAtIndex:0];
//                }
//            }
//            
//            if(conversionResult == 0)
//            {                
//                DDLogDebug(@"Decompressed buffer with length %d", (int)outAudioBufferList.mBuffers[0].mDataByteSize);
//
//                NSMutableData* buffer = [NSMutableData dataWithBytes:outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
//                [self pushPlayQueueBuffer:buffer];
//            }
//            else
//            {
//                if(self.isPlaying)
//                {
//                    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:conversionResult userInfo:nil];
//                    char code[5];
//                    memcpy(code, &conversionResult, 4);
//                    code[4] = 0;
//                    DDLogError(@"Decompress error %s  %@", code, error);
//                }
//            }
//        }
//        else
//        {
//            [NSThread sleepForTimeInterval:0.1];
//        }
//    }
    
    DDLogInfo(@"Decompression thread stopping");
}

//- (OSStatus)handleDecompressBuffer:(UInt32*)ioNumberDataPackets data:(AudioBufferList*)ioData description:(AudioStreamPacketDescription**)outDataPacketDescription
//{
//    OSStatus status = noErr;
//    
//    [self.decompressCondition lock];
//    
//    if(self.decompressQueue.count == 0)
//    {
//        [self.decompressCondition wait];
//    }
//    
//    if(self.isPlaying)
//    {
//        NSMutableData* buffer;
//        @synchronized(self.decompressQueue)
//        {
//            buffer = [self.decompressQueue firstObject];
//        }
//        
//        ioData->mNumberBuffers = 1;
//        ioData->mBuffers[0].mNumberChannels = 1;
//        ioData->mBuffers[0].mDataByteSize = (UInt32)buffer.length;
//        ioData->mBuffers[0].mData = [buffer mutableBytes];
//        
//        *ioNumberDataPackets = 128;//ioData->mBuffers[0].mDataByteSize / 2;
//        
////        (*outDataPacketDescription)->mStartOffset = 0;
////        (*outDataPacketDescription)->mVariableFramesInPacket = 0;
////        (*outDataPacketDescription)->mDataByteSize = ioData->mBuffers[0].mDataByteSize;
//
//        AudioStreamPacketDescription* pd = (AudioStreamPacketDescription *)(malloc(sizeof(AudioStreamPacketDescription)));
//        pd->mStartOffset = 0;
//        pd->mVariableFramesInPacket = 0;
//        pd->mDataByteSize = ioData->mBuffers[0].mDataByteSize;
//        
//        memcpy(*outDataPacketDescription, &pd, sizeof(AudioStreamPacketDescription));
//    }
//    else
//    {
//        ioData->mBuffers[0].mDataByteSize = 0;
//        *ioNumberDataPackets = 0;
//        status = -1;
//    }
//    
//    [self.decompressCondition unlock];
//    
//    return status;
//}

//static OSStatus handleDecompressBuffer(AudioConverterRef inAudioConverter,
//                                       UInt32* ioNumberDataPackets,
//                                       AudioBufferList* ioData,
//                                       AudioStreamPacketDescription** outDataPacketDescription,
//                                       void* inUserData)
//{
//    unsigned char* pd1 = (unsigned char*)outDataPacketDescription;
//    unsigned char* pd2 = (unsigned char*)*outDataPacketDescription;
//    unsigned char* pd3 = (unsigned char*)outDataPacketDescription[0];
//
//    AudioManager* manager = (__bridge AudioManager*)inUserData;
//    return [manager handleDecompressBuffer:ioNumberDataPackets data:ioData description:outDataPacketDescription];
//}


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
