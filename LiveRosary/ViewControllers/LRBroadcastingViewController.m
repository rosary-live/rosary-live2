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
#import "LiveRosaryService.h"
#import "UserManager.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface LRBroadcastingViewController ()

@property (nonatomic, weak) IBOutlet F3BarGauge* meter;
@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, weak) IBOutlet UILabel* broadcastTime;
@property (nonatomic, weak) IBOutlet UIButton* stopButton;

@property (nonatomic, strong) NSString* broadcastId;
@property (nonatomic, strong) NSTimer* meterTimer;
@property (nonatomic, strong) NSMutableArray* listeners;

@property (nonatomic) CFTimeInterval startTime;

@end

@implementation LRBroadcastingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.meter.minLimit = 0.0;
    self.meter.maxLimit = 1.0;
    self.meter.holdPeak = NO;
    
    self.listeners = [NSMutableArray new];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[BroadcastManager sharedManager] startBroadcastingWithCompletion:^(NSString *brodcastId, BOOL insufficientBandwidth) {
        self.broadcastId = brodcastId;
        
        if(insufficientBandwidth)
        {
            [UIAlertView bk_showAlertViewWithTitle:nil message:@"Insufficient bandwidth to broadcast." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
        else
        {
            self.startTime = CACurrentMediaTime();
            
            __block NSInteger timerCounter = 0;
            self.meterTimer = [NSTimer bk_scheduledTimerWithTimeInterval:0.05 block:^(NSTimer *timer) {
                Float32 level;
                Float32 peak;
                [[AudioManager sharedManager] inputAveragePowerLevel:&level peakHoldLevel:&peak];
                self.meter.value = pow(10, level/40);
                
                // Only update broadcast time label once per second
                if(timerCounter % 20 == 0)
                {
                    int totalSeconds = (int)(CACurrentMediaTime() - self.startTime);
                    int minutes = totalSeconds / 60;
                    int seconds = totalSeconds % 60;
                    
                    int totalRemainingSeconds = (int)[ConfigModel sharedInstance].maxBroadcastSeconds - totalSeconds;
                    int remainingMinutes = totalRemainingSeconds / 60;
                    int remainingSeconds = totalRemainingSeconds % 60;
                    
                    self.broadcastTime.text = [NSString stringWithFormat:@"%d:%02d / %d:%02d", minutes, seconds, remainingMinutes, remainingSeconds];
                    
                    if(totalRemainingSeconds < 300)
                    {
                        self.broadcastTime.textColor = [UIColor orangeColor];
                    }
                    else if(totalRemainingSeconds < 120)
                    {
                        self.broadcastTime.textColor = [UIColor redColor];
                    }
                    else if(totalRemainingSeconds <= 0)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self stopBroadcasting];
                        });
                    }
                }
            } repeats:YES];
            
            [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
            
            [[LiveRosaryService sharedService] startBroadcastingWithEmail:[UserManager sharedManager].email andBroadcastId:brodcastId completion:^(NSError *error) {
                [[BroadcastQueueModel sharedInstance] startReceivingForBroadcastId:brodcastId asBroadcaster:YES event:^(NSArray *events) {
                    NSLog(@"events %@", events);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        for(NSDictionary* event in events)
                        {
                            NSString* type = event[@"type"];
                            if([type isEqualToString:@"enter"])
                            {
                                NSDictionary* listener = event[@"event"];
                                if([self listenerForEmail:listener[@"email"]] == nil)
                                {
                                    [self.listeners addObject:listener];
                                    [[AnalyticsManager sharedManager] event:@"EnterBroadcast" info:@{@"bid": brodcastId}];
                                    
                                }
                                else
                                {
                                    [[AnalyticsManager sharedManager] event:@"EnterBroadcastDuplicate" info:@{@"bid": brodcastId}];
                                }
                            }
                            else if([type isEqualToString:@"exit"])
                            {
                                NSDictionary* listener = event[@"event"];
                                NSDictionary* existingListener = [self listenerForEmail:listener[@"email"]];
                                if(existingListener != nil)
                                {
                                    [[AnalyticsManager sharedManager] event:@"ExitBroadcast" info:@{@"bid": brodcastId}];
                                    [self.listeners removeObject:existingListener];
                                }
                                else
                                {
                                    [[AnalyticsManager sharedManager] event:@"ExitBroadcastDuplicate" info:@{@"bid": brodcastId}];
                                }
                            }
                            else if([type isEqualToString:@"update"])
                            {
                                NSDictionary* listener = event[@"event"];
                                NSDictionary* existingListener = [self listenerForEmail:listener[@"email"]];
                                if(existingListener != nil)
                                {
                                    NSUInteger index = [self.listeners indexOfObject:existingListener];
                                    if(index != NSNotFound)
                                    {
                                        [[AnalyticsManager sharedManager] event:@"UpdateBroadcast" info:@{@"bid": brodcastId}];
                                        
                                        [self.listeners replaceObjectAtIndex:index withObject:listener];
                                    }
                                    else
                                    {
                                        [[AnalyticsManager sharedManager] event:@"UpdateBroadcastDuplicate" info:@{@"bid": brodcastId}];
                                    }
                                }
                            }
                        }
                        
                        [self.tableView reloadData];
                    });
                }];
            }];
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

- (NSString*)screenName
{
    return @"Broadcasting";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSDictionary*)listenerForEmail:(NSString*)email
{
    if(email != nil && email.length > 0)
    {
        NSPredicate* byEmail = [NSPredicate predicateWithFormat:@"email == %@", email];
        NSArray* result = [self.listeners filteredArrayUsingPredicate:byEmail];
        if(result != nil && result.count > 0)
        {
            return result[0];
        }
    }
    
    return nil;
}

- (IBAction)onStopRecording:(id)sender
{
    [self stopBroadcasting];
}

- (void)stopBroadcasting
{
    if([BroadcastManager sharedManager].state == BroadcastStateBroadcasting)
    {
        self.stopButton.hidden = YES;
        
        [self.meterTimer invalidate];

        [[AnalyticsManager sharedManager] event:@"BroadcastDuration" info:@{@"bid": self.broadcastId, @"duration": @(CACurrentMediaTime() - self.startTime)}];
        
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        
        [[BroadcastQueueModel sharedInstance] stopReceiving];
        [[BroadcastManager sharedManager] stopBroadcasting];
        self.meter.value = 0.0;
    }
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
    NSDictionary* listener = self.listeners[indexPath.row];
    cell.name.text = [NSString stringWithFormat:@"%@ %@", listener[@"firstName"], listener[@"lastName"]];
    cell.location.text = [NSString stringWithFormat:@"%@ %@ %@", listener[@"city"], listener[@"state"], listener[@"country"]];
    cell.intention.text = listener[@"intention"];
    
    NSString* urlString = [NSString stringWithFormat:@"https://s3.amazonaws.com/liverosaryavatars/%@", [listener[@"email"] stringByReplacingOccurrencesOfString:@"@" withString:@"-"]];
    [cell.avatar sd_setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:[UIImage imageNamed:@"AvatarImage"] options:0];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70.0f;
}

@end
