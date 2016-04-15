//
//  LRAdminMainViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/13/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRAdminBroadcastsViewController.h"
#import "LRListenViewController.h"
#import "BroadcastsViewController.h"
#import "UserManager.h"
#import <PureLayout/PureLayout.h>

@interface LRAdminBroadcastsViewController () <BroadcastsViewDelegate>

@property (nonatomic, strong) BroadcastsViewController* broadcastViewController;

@end

@implementation LRAdminBroadcastsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self addBroadcasts];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self.broadcastViewController action:@selector(update)];

    if([UserManager sharedManager].isAuthenticated)
    {
        [self.broadcastViewController update];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)screenName
{
    return @"Admin Broadcasts";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - BroadcastsTableViewActionDelegate

- (void)selectedBroadcast:(BroadcastModel*)broadcast
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LRListenViewController* listenViewController = [storyboard instantiateViewControllerWithIdentifier:@"LRListenViewController"];
    listenViewController.broadcast = broadcast;
    listenViewController.playFromStart = YES;
    [self.navigationController pushViewController:listenViewController animated:YES];
}

- (void)selectedSchedule:(ScheduleModel *)model
{
}

- (void)addBroadcasts
{
    self.broadcastViewController = [BroadcastsViewController instantiate];
    self.broadcastViewController.delegate = self;
    self.broadcastViewController.showReportedBroadcasts = NO;
    self.broadcastViewController.liveOnly = NO;
    self.broadcastViewController.allScheduledBroadcasts = YES;
    
    [self addChildViewController:self.broadcastViewController];
    [self.view addSubview:self.broadcastViewController.view];
    [self.broadcastViewController.view autoPinEdgesToSuperviewEdges];
    [self.broadcastViewController didMoveToParentViewController:self];
}

@end
