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

@interface LRListenMainViewController () <UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, strong) NSArray<BroadcastModel *> *broadcasts;

@end

@implementation LRListenMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addDrawerButton];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(updatBroadcasts)];
    
    
    if([UserManager sharedManager].isLoggedIn)
    {
//        [[UserManager sharedManager] refreshTokenWithCompletion:^(NSError *error) {
//            [self test];
//            
            if([[UserManager sharedManager] credentialsExpired])
            {
                [[UserManager sharedManager] refreshCredentialsWithCompletion:^(NSError* error) {
                    [self updatBroadcasts];
                }];
            }
            else
            {
                [self updatBroadcasts];
            }
//        }];
    }
    else
    {
        [[UserManager sharedManager] loginWithEmail:@"richard@softwarelogix.com" password:@"qwerty" completion:^(NSError *error) {
            [self updatBroadcasts];
        }];
    }
}

- (void)updatBroadcasts
{
    [[DBBroadcast sharedInstance] updateBroadcastsWithCompletion:^(NSArray<BroadcastModel *> *broadcasts, NSError *error) {
        self.broadcasts = broadcasts;
        [self sortBroadcasts];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

- (void)sortBroadcasts
{
    NSSortDescriptor* byDate = [NSSortDescriptor sortDescriptorWithKey:@"created" ascending:YES];
    self.broadcasts = [self.broadcasts sortedArrayUsingDescriptors:@[byDate]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    LRListenViewController* listenViewController = (LRListenViewController*)segue.destinationViewController;
    BroadcastCell* cell = (BroadcastCell*)sender;
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    listenViewController.broadcast = self.broadcasts[indexPath.row];
}

- (IBAction)onPlayStopButton:(id)sender
{
    if([BroadcastManager sharedManager].state == BroadcastStatePlaying)
    {
        [[BroadcastManager sharedManager] stopPlaying];
    }
    else if([BroadcastManager sharedManager].state == BroadcastStateIdle)
    {
        [[BroadcastManager sharedManager] startPlayingBroadcastWithId:@""];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.broadcasts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BroadcastCell* cell = [tableView dequeueReusableCellWithIdentifier:@"BroadcastCell"];
    
    BroadcastModel* broadcast = self.broadcasts[indexPath.row];
    cell.name.text = broadcast.name;
    cell.language.text = broadcast.language;
    cell.location.text = [NSString stringWithFormat:@"%@, %@ %@", broadcast.city, broadcast.state, broadcast.country];
    cell.date.text = [NSDateFormatter localizedStringFromDate:[broadcast.updated dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    return cell;
}

@end
