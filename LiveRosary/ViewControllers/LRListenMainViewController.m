//
//  LRListenMainViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/11/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRListenMainViewController.h"
#import "UserManager.h"
#import "AudioManager.h"
#import "TransferManager.h"

@interface LRListenMainViewController () <TransferManagerDelegate, AudioManagerDelegate>

@property (nonatomic, weak) IBOutlet UIButton* playStopButton;

@end

@implementation LRListenMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addDrawerButton];
    
    if([UserManager sharedManager].isLoggedIn)
    {
        if([[UserManager sharedManager] credentialsExpired])
        {
            [[UserManager sharedManager] refreshCredentialsWithCompletion:^(NSError* error) {
            }];
        }
    }
    else
    {
        [[UserManager sharedManager] loginWithEmail:@"richard@softwarelogix.com" password:@"qwerty" completion:^(NSError *error) {
        }];
    }
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

- (IBAction)onPlayStopButton:(id)sender
{
    [AudioManager sharedManager].delegate = self;
    [AudioManager sharedManager].sampleRate = 11025.0;
    [AudioManager sharedManager].channels = 1;
    [TransferManager sharedManager].delegate = self;
    [[TransferManager sharedManager] startReceiving:@"AFD4B5EF-540E-44FB-BFD0-B40478F2BA7D" atSequence:1];
    
    [[AudioManager sharedManager] prepareToPlay];
}

- (void)receivedFile:(NSString*)filename forSequence:(NSInteger)sequence
{
    [[AudioManager sharedManager] addAudioFileToPlay:filename];
    
    if(![AudioManager sharedManager].isPlaying)
    {
        [[AudioManager sharedManager] startPlaying];
    }
}

//- (void)receivedData:(NSData*)data forSequence:(NSInteger)sequence
//{
//    DDLogDebug(@"Received %d bytes for sequence %d", (int)data.length, (int)sequence);
//    
//    NSUInteger position = 0;
//    unsigned short packets;
//    [data getBytes:&packets range:NSMakeRange(0, sizeof(packets))];
//    position += sizeof(packets);
//    
//    char* buffer = malloc(32768);
//    for(int i = 0; i < packets; i++)
//    {
//        unsigned short length;
//        [data getBytes:&length range:NSMakeRange(position, sizeof(length))];
//        position += sizeof(length);
//        [data getBytes:buffer range:NSMakeRange(position, length)];
//        position += length;
//        DDLogDebug(@"Adding buffer to play with length %d", length);
//        [[AudioManager sharedManager] addAudioDataToPlay:[NSData dataWithBytes:buffer length:length]];
//    }
//    
//    free(buffer);
//    
//    if([AudioManager sharedManager].playBufferCount > 10)
//    {
//        [[AudioManager sharedManager] startPlaying];
//    }
//}
//
//- (void)receiveError:(NSError*)error
//{
//}
//
//- (void)audioError:(NSError*)error
//{
//}

@end
