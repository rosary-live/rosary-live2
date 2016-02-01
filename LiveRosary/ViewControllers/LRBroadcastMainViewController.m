//
//  LRBroadcastMainViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/13/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRBroadcastMainViewController.h"
#import "BroadcastManager.h"

@interface LRBroadcastMainViewController ()

@property (nonatomic, weak) IBOutlet UIButton* startStopButton;
@property (nonatomic, weak) IBOutlet UILabel* infoLabel;

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
    if([BroadcastManager sharedManager].state == BroadcastStateBroadcasting)
    {
        [self.startStopButton setTitle:@"Start" forState:UIControlStateNormal];
        [[BroadcastManager sharedManager] stopBroadcasting];
    }
    else if([BroadcastManager sharedManager].state == BroadcastStateIdle)
    {
        [self.startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
        [[BroadcastManager sharedManager] startBroadcasting];        
    }
}

@end
