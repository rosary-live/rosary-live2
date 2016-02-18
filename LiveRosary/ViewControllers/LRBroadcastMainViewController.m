//
//  LRBroadcastMainViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/13/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRBroadcastMainViewController.h"
#import "BroadcastManager.h"
#import "AudioManager.h"
#import "F3BarGauge.h"

@interface LRBroadcastMainViewController ()

@property (nonatomic, weak) IBOutlet UIButton* startStopButton;
@property (nonatomic, weak) IBOutlet UILabel* infoLabel;
@property (nonatomic, weak) IBOutlet F3BarGauge* meter;

@property (nonatomic, strong) NSTimer* meterTimer;

@end

@implementation LRBroadcastMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self addDrawerButton];
    
    self.meter.minLimit = 0.0;
    self.meter.maxLimit = 1.0;
    self.meter.holdPeak = NO;
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
    if([BroadcastManager sharedManager].state == BroadcastStateBroadcasting)
    {
        [self.startStopButton setTitle:@"Start" forState:UIControlStateNormal];
        [[BroadcastManager sharedManager] stopBroadcasting];
        self.meter.value = 0.0;
    }
    else if([BroadcastManager sharedManager].state == BroadcastStateIdle)
    {
        [self.startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
        [[BroadcastManager sharedManager] startBroadcasting];
        
        self.meterTimer = [NSTimer bk_scheduledTimerWithTimeInterval:0.05 block:^(NSTimer *timer) {
            Float32 level;
            Float32 peak;
            [[AudioManager sharedManager] inputAveragePowerLevel:&level peakHoldLevel:&peak];
            self.meter.value = pow(10, level/40);
        } repeats:YES];
    }
}

@end
