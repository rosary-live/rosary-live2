//
//  LRListenMainViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/11/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRListenMainViewController.h"
#import "LRListenViewController.h"
#import "UserManager.h"
#import "BroadcastManager.h"
#import "DBBroadcast.h"
#import "BroadcastCell.h"
#import "NSNumber+Utilities.h"
#import "BroadcastsViewController.h"
#import <PureLayout/PureLayout.h>

@interface LRListenMainViewController () <BroadcastsViewDelegate>

@property (nonatomic, strong) BroadcastsViewController* broadcastViewController;

@property (nonatomic, strong) NSArray<BroadcastModel *> *broadcasts;

@end

@implementation LRListenMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addDrawerButton];
    [self addBroadcasts];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self.broadcastViewController action:@selector(updateBroadcasts)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    LRListenViewController* listenViewController = (LRListenViewController*)segue.destinationViewController;
//    BroadcastCell* cell = (BroadcastCell*)sender;
//    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
//    listenViewController.broadcast = self.broadcasts[indexPath.row];
//    listenViewController.playFromStart = NO;
//}

- (void)addBroadcasts
{
    self.broadcastViewController = [BroadcastsViewController instantiate];
    self.broadcastViewController.delegate = self;
    self.broadcastViewController.liveOnly = YES;
    
    [self addChildViewController:self.broadcastViewController];
    [self.view addSubview:self.broadcastViewController.view];
    [self.broadcastViewController.view autoPinEdgesToSuperviewEdges];
    [self.broadcastViewController didMoveToParentViewController:self];
}

#pragma mark - BroadcastsViewDelegate

- (void)selectedBroadcast:(BroadcastModel*)broadcast
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LRListenViewController* listenViewController = [storyboard instantiateViewControllerWithIdentifier:@"LRListenViewController"];
    listenViewController.broadcast = broadcast;
    listenViewController.playFromStart = NO;
    [self.navigationController pushViewController:listenViewController animated:YES];
}

@end
