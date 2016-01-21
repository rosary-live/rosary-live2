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

@interface LRListenMainViewController () <AudioManagerDelegate>

@end

@implementation LRListenMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addDrawerButton];
    
    [[UserManager sharedManager] loginWithEmail:@"richard@softwarelogix.com" password:@"qwerty" completion:^(NSError *error) {
    }];
    
    [AudioManager sharedManager].delegate = self;
    
    [AudioManager sharedManager].sampleRate = 44100.0;
    [AudioManager sharedManager].channels = 1;
    [[AudioManager sharedManager] startRecording];
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


- (void)audioError:(NSError*)error
{
    DDLogError(@"AudioManager error: %@", error);
}

- (void)capturedAudioData:(NSData*)audio
{
    DDLogDebug(@"Audio captured %d", (int)audio.length);
}

@end
