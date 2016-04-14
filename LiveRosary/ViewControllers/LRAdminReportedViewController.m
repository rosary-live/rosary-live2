//
//  LRAdminReportedBroadcastsViewController.m
//  LiveRosary
//
//  Created by Richard Taylor on 4/13/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRAdminReportedViewController.h"
#import "UserManager.h"
#import <PureLayout/PureLayout.h>

@interface LRAdminReportedViewController () <BroadcastsViewDelegate>

@end

@implementation LRAdminReportedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(updateBroadcasts)];
    
    if([UserManager sharedManager].isAuthenticated)
    {
        [self updateBroadcasts];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (void)updateBroadcasts
{
}

@end
