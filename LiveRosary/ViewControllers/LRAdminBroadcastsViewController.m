//
//  LRAdminMainViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/13/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRAdminBroadcastsViewController.h"
#import "BroadcastsTableView.h"
#import "LRListenViewController.h"

@interface LRAdminBroadcastsViewController () <BroadcastsTableViewActionDelegate>

@property (nonatomic, weak) IBOutlet BroadcastsTableView* tableView;

@end

@implementation LRAdminBroadcastsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.actionDelegate = self;
        
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self.tableView action:@selector(updateBroadcasts)];
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

#pragma mark - BroadcastsTableViewActionDelegate

- (void)selectedBroadcast:(BroadcastModel*)broadcast
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LRListenViewController* listenViewController = [storyboard instantiateViewControllerWithIdentifier:@"LRListenViewController"];
    listenViewController.broadcast = broadcast;
    listenViewController.playFromStart = YES;
    [self.navigationController pushViewController:listenViewController animated:YES];
}

@end
