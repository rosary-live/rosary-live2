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

@property (nonatomic, strong) UIView* loadingView;
@property (nonatomic, strong) UIActivityIndicatorView* spinner;

@property (nonatomic, strong) NSArray<BroadcastModel *> *broadcasts;


@end

@implementation LRListenMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addDrawerButton];
    [self addBroadcasts];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self.broadcastViewController action:@selector(update)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loggedIn) name:NotificationUserLoggedIn object:nil];
    
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
    self.loadingView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.loadingView.backgroundColor = [UIColor whiteColor];
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = CGPointMake([[UIScreen mainScreen]bounds].size.width/2, [[UIScreen mainScreen]bounds].size.height/2);
    [self.spinner startAnimating];
    [self.loadingView addSubview:self.spinner];
    [self.view addSubview:self.loadingView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if([UserManager sharedManager].isAuthenticated)
    {
        if([UserManager sharedManager].currentUser.userLevel != UserLevelBanned)
        {
            [self removeSpinner];
            [self.broadcastViewController update];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)screenName
{
    return @"Listen Main";
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

- (void)removeSpinner
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self navigationController] setNavigationBarHidden:NO animated:NO];
        [self.spinner stopAnimating];
        [self.spinner removeFromSuperview];
        [self.loadingView removeFromSuperview];
    });
}

- (void)loggedIn
{
    if([UserManager sharedManager].currentUser.userLevel != UserLevelBanned)
    {
        [self removeSpinner];
        [self.broadcastViewController update];
    }
}

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

- (void)selectedSchedule:(ScheduleModel *)model
{
}

@end
