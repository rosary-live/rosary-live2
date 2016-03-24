//
//  LRBroadcastMainViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/13/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRBroadcastMainViewController.h"
#import "ScheduleManager.h"
#import "ScheduleSingleCell.h"
#import "NSNumber+Utilities.h"
#import "LRScheduleBroadcastViewController.h"

@interface LRBroadcastMainViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView* tableView;

@property (nonatomic, strong) NSArray<ScheduleModel*>* scheduledBroadcasts;

@end

@implementation LRBroadcastMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self addDrawerButton];    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[ScheduleManager sharedManager] myScheduledBroadcastsWithCompletion:^(NSArray<ScheduleModel *> *scheduledBroadcasts, NSError *error) {
        self.scheduledBroadcasts = scheduledBroadcasts;
        [self filterScheduledBroadcasts];
        [self sortScheduledBroadcasts];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([sender isKindOfClass:[UITableViewCell class]])
    {
        LRScheduleBroadcastViewController* scheduleBroadcastViewController = [segue destinationViewController];
        NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
        scheduleBroadcastViewController.scheduledBroadcast = self.scheduledBroadcasts[indexPath.row];
    }
}

- (void)filterScheduledBroadcasts
{
}

- (void)sortScheduledBroadcasts
{
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.scheduledBroadcasts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ScheduleSingleCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ScheduleCell" forIndexPath:indexPath];
    
    ScheduleModel* schedule = self.scheduledBroadcasts[indexPath.row];

    if(schedule.isSingle)
    {
        cell.schedule.text = [NSString stringWithFormat:@"%@ %@", [NSDateFormatter localizedStringFromDate:[schedule.start dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], [NSDateFormatter localizedStringFromDate:[schedule.start dateForNumber] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle]];
    }
    else
    {
        cell.schedule.text = [NSString stringWithFormat:@"From %@ to %@\n%@ at %@", [NSDateFormatter localizedStringFromDate:[schedule.from dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], [NSDateFormatter localizedStringFromDate:[schedule.to dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], [schedule.days daysString], [schedule.at time]];
    }
    
    return cell;
}


//#pragma mark - UITableViewDelegate
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//}

@end
