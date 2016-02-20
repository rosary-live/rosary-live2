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
#import "BroadcastsTableView.h"

@interface LRListenMainViewController () <BroadcastsTableViewActionDelegate>

@property (nonatomic, weak) IBOutlet BroadcastsTableView* tableView;
@property (nonatomic, strong) NSArray<BroadcastModel *> *broadcasts;

@end

@implementation LRListenMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addDrawerButton];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self.tableView action:@selector(updateBroadcasts)];
    
    self.tableView.actionDelegate = self;
    self.tableView.liveOnly = YES;
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

#pragma mark - BroadcastsTableViewActionDelegate

- (void)selectedBroadcast:(BroadcastModel*)broadcast
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LRListenViewController* listenViewController = [storyboard instantiateViewControllerWithIdentifier:@"LRListenViewController"];
    listenViewController.broadcast = broadcast;
    listenViewController.playFromStart = NO;
    [self.navigationController pushViewController:listenViewController animated:YES];
}

@end
