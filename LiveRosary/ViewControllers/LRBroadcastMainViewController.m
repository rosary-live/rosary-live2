//
//  LRBroadcastMainViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/13/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRBroadcastMainViewController.h"
#import "AudioManager.h"
#import "TransferManager.h"
#import "NSString+Utilities.h"

@interface LRBroadcastMainViewController () <AudioManagerDelegate>

@property (nonatomic, weak) IBOutlet UIButton* startStopButton;
@property (nonatomic, weak) IBOutlet UILabel* infoLabel;
//@property (nonatomic, strong) NSMutableData* audioData;
//@property (nonatomic) double totalSeconds;
//@property (nonatomic) NSInteger packetCount;

@end

@implementation LRBroadcastMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self addDrawerButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onStartStopButton:(id)sender
{
    if([AudioManager sharedManager].isRecording)
    {
        [self.startStopButton setTitle:@"Start" forState:UIControlStateNormal];
        [[AudioManager sharedManager] stopRecording];
    }
    else
    {
        [self.startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
//        self.audioData = [NSMutableData new];
//        self.totalSeconds = 0;
//        self.packetCount = 0;
//        
//        // Packet count placeholder
//        unsigned short packets = 0;
//        [self.audioData appendBytes:&packets length:sizeof(packets)];
        
        NSString* broadcastId = [NSString UUID];
        [[TransferManager sharedManager] startSending:broadcastId];
        //[[TransferManager sharedManager] addSequenceData:[self infoDataForBroadcastId:broadcastId]];
        NSString* filename = [NSString filenameForBroadcastId:broadcastId andSequence:0];
        [[self infoDataForBroadcastId:broadcastId] writeToFile:filename atomically:NO];
        [[TransferManager sharedManager] addSequenceFile:filename];
        
        [AudioManager sharedManager].delegate = self;
//        [AudioManager sharedManager].sampleRate = 44100.0;
        [AudioManager sharedManager].sampleRate = 11025.0;
        [AudioManager sharedManager].channels = 1;
        [[AudioManager sharedManager] startRecording:broadcastId];
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

- (void)capturedAudioFile:(NSString*)filename sequence:(NSInteger)sequence secondsOfAudio:(double)seconds
{
    [[TransferManager sharedManager] addSequenceFile:filename];
    DDLogDebug(@"Added file to send: %@", filename);
}

//- (void)audioError:(NSError*)error
//{
//    DDLogError(@"AudioManager error: %@", error);
//}
//
//- (void)capturedAudioData:(NSData*)audio secondsOfAudio:(double)seconds
//{
//    unsigned short length = (unsigned short)audio.length;
//    [self.audioData appendBytes:&length length:sizeof(length)];
//    [self.audioData appendData:audio];
//    self.totalSeconds += seconds;
//    ++self.packetCount;
//    NSInteger bytesPerSecond = self.audioData.length / self.totalSeconds;
//    
//    if(self.totalSeconds >= 10.0)
//    {
//        unsigned short packets = (unsigned short)self.packetCount;
//        DDLogDebug(@"Number of packets in sequence: %d", (int)self.packetCount);
//        
//        [self.audioData replaceBytesInRange:NSMakeRange(0, 2) withBytes:&packets];
//        [[TransferManager sharedManager] addSequenceData:self.audioData];
//        self.audioData = [NSMutableData new];
//        packets = 0;
//        [self.audioData appendBytes:&packets length:sizeof(packets)];
//        self.totalSeconds = 0.0;
//        self.packetCount = 0;
//        
//        DDLogDebug(@"Added buffer to send");
//    }
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.infoLabel.text = [NSString stringWithFormat:@"%d %g %d", (int)self.audioData.length, self.totalSeconds, (int)bytesPerSecond];
//    });
//}

@end
