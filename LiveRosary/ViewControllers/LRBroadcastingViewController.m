//
//  LRBroadcastingViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 3/19/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRBroadcastingViewController.h"
#import "BroadcastManager.h"
#import "AudioManager.h"
#import "F3BarGauge.h"
#import "BroadcastQueueModel.h"
#import "ListenerCell.h"

@interface LRBroadcastingViewController ()

@property (nonatomic, weak) IBOutlet F3BarGauge* meter;

@property (nonatomic, strong) NSTimer* meterTimer;
@property (nonatomic, strong) NSArray* listeners;

@end

@implementation LRBroadcastingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.meter.minLimit = 0.0;
    self.meter.maxLimit = 1.0;
    self.meter.holdPeak = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[BroadcastManager sharedManager] startBroadcastingWithCompletion:^(NSString *brodcastId, BOOL insufficientBandwidth) {
        if(insufficientBandwidth)
        {
            [UIAlertView bk_showAlertViewWithTitle:nil message:@"Insufficient bandwidth to broadcast." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
        else
        {
            self.meterTimer = [NSTimer bk_scheduledTimerWithTimeInterval:0.05 block:^(NSTimer *timer) {
                Float32 level;
                Float32 peak;
                [[AudioManager sharedManager] inputAveragePowerLevel:&level peakHoldLevel:&peak];
                self.meter.value = pow(10, level/40);
            } repeats:YES];
            
            [[BroadcastQueueModel sharedInstance] startReceivingForBroadcastId:brodcastId event:^(NSArray *events) {
                NSLog(@"events %@", events);
            }];
//
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [[BroadcastQueueModel sharedInstance] sendEnterForBroadcastId:brodcastId withDictionary:@{ @"test": @"this is a test" }];
//            });
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopBroadcasting];
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

- (IBAction)onStopRecording:(id)sender
{
    [self stopBroadcasting];
}

- (void)stopBroadcasting
{
    [[BroadcastQueueModel sharedInstance] stopReceiving];
    [[BroadcastManager sharedManager] stopBroadcasting];
    self.meter.value = 0.0;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.listeners.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Listeners";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ListenerCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ListenerCell" forIndexPath:indexPath];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70.0f;
}

@end
