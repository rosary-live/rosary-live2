//
//  LRAdminReportedBroadcastsViewController.m
//  LiveRosary
//
//  Created by Richard Taylor on 4/13/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRAdminReportedViewController.h"
#import "UserManager.h"
#import "BroadcastsViewController.h"
#import "LRListenViewController.h"
#import <PureLayout/PureLayout.h>

@interface LRAdminReportedViewController () <BroadcastsViewDelegate>

@property (nonatomic, strong) BroadcastsViewController* broadcastViewController;

@end

@implementation LRAdminReportedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addBroadcasts];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self.broadcastViewController action:@selector(update)];
    
    if([UserManager sharedManager].isAuthenticated)
    {
        [self.broadcastViewController update];
    }
}

- (NSString*)screenName
{
    return @"Admin Reported Broadcasts";
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

- (void)selectedReportedBroadcast:(ReportedBroadcastModel *)model
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LRListenViewController* listenViewController = [storyboard instantiateViewControllerWithIdentifier:@"LRListenViewController"];
    listenViewController.reportedBroadcast = model;
    listenViewController.playFromStart = YES;
    [self.navigationController pushViewController:listenViewController animated:YES];
}

- (void)addBroadcasts
{
    self.broadcastViewController = [BroadcastsViewController instantiate];
    self.broadcastViewController.delegate = self;
    self.broadcastViewController.showReportedBroadcasts = YES;
    
    [self addChildViewController:self.broadcastViewController];
    [self.view addSubview:self.broadcastViewController.view];
    [self.broadcastViewController.view autoPinEdgesToSuperviewEdges];
    [self.broadcastViewController didMoveToParentViewController:self];
}

@end
