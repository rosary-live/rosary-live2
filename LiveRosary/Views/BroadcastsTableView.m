//
//  BroadcastsTableView.m
//  LiveRosary
//
//  Created by richardtaylor on 2/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "BroadcastsTableView.h"
#import "BroadcastCell.h"
#import "UserManager.h"
#import "BroadcastManager.h"
#import "DBBroadcast.h"
#import "NSNumber+Utilities.h"

@interface BroadcastsTableView() <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray<BroadcastModel *> *broadcasts;

@end

@implementation BroadcastsTableView

- (void)awakeFromNib
{
    self.dataSource = self;
    self.delegate = self;
    
    UINib* cellNib = [UINib nibWithNibName:@"BroadcastCell" bundle:nil];
    [self registerNib:cellNib forCellReuseIdentifier:@"BroadcastCell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBroadcasts) name:NotificationUserLoggedIn object:nil];

    if([UserManager sharedManager].isLoggedIn)
    {
        [self updateBroadcasts];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateBroadcasts
{
    [[DBBroadcast sharedInstance] updateBroadcastsWithCompletion:^(NSArray<BroadcastModel *> *broadcasts, NSError *error) {
        self.broadcasts = broadcasts;
        [self filterBroadcasts];
        [self sortBroadcasts];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
        });
    }];
}

- (void)sortBroadcasts
{
    NSSortDescriptor* byDate = [NSSortDescriptor sortDescriptorWithKey:@"created" ascending:YES];
    self.broadcasts = [self.broadcasts sortedArrayUsingDescriptors:@[byDate]];
}

- (void)filterBroadcasts
{
    if(self.liveOnly)
    {
        NSPredicate* filter = [NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return ((BroadcastModel*)evaluatedObject).isLive;
        }];
        
        self.broadcasts = [self.broadcasts filteredArrayUsingPredicate:filter];
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
    cell.live.text = broadcast.isLive ? @"LIVE" : @"ENDED";
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.actionDelegate != nil && [self.actionDelegate respondsToSelector:@selector(selectedBroadcast:)])
    {
        [self.actionDelegate selectedBroadcast:self.broadcasts[indexPath.row]];
    }
}

@end
