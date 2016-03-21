//
//  LRBroadcastScheduleViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 3/19/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRScheduleBroadcastViewController.h"
#import "NSNumber+Utilities.h"
#import "SegmentedSettingCell.h"
#import "ValueSettingCell.h"
#import "ButtonSettingCell.h"

typedef NS_ENUM(NSUInteger, CellType) {
    CellTypeType,
    CellTypeDate,
    CellTypeFrom,
    CellTypeTo,
    CellTypeAt,
    CellTypeDays,
    CellTypeSave,
    CellTypeDelete
};

@interface LRScheduleBroadcastViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView* tableView;

@property (nonatomic) BOOL existing;
@property (nonatomic) BOOL single;
@property (nonatomic, strong) NSDate* start;
@property (nonatomic, strong) NSDate* from;
@property (nonatomic, strong) NSDate* to;
@property (nonatomic, strong) NSNumber* at;
@property (nonatomic, strong) NSNumber* days;

@end

@implementation LRScheduleBroadcastViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.scheduledBroadcast != nil)
    {
        self.existing = YES;
        self.single = self.scheduledBroadcast.isSingle;
        self.start = [self.scheduledBroadcast.start dateForNumber];
        self.from = [self.scheduledBroadcast.from dateForNumber];
        self.to = [self.scheduledBroadcast.to dateForNumber];
        self.at = self.scheduledBroadcast.at;
        self.days = self.scheduledBroadcast.days;
    }
    else
    {
        self.existing = NO;
        self.single = YES;
        self.start = [NSDate date];
        self.from = [NSDate date];
        self.to = [NSDate date];
        self.at = @(0);
        self.days = @(0);
    }
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

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 2; // type, save
    
    if(self.existing)
    {
        count += 1; // delete
    }
    
    if(self.single)
    {
        count += 1; // date
    }
    else
    {
        count += 4; // from, to, at, days
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CellType ct;
    
    if(indexPath.row == 0)
    {
        ct = CellTypeType;
    }
    else
    {
        if(self.single)
        {
            if(indexPath.row == 1)
            {
                ct = CellTypeDate;
            }
            else if(indexPath.row == 2)
            {
                ct = CellTypeSave;
            }
            else if(self.existing)
            {
                ct = CellTypeDelete;
            }
        }
        else
        {
            if(indexPath.row == 1)
            {
                ct = CellTypeFrom;
            }
            else if(indexPath.row == 2)
            {
                ct = CellTypeTo;
            }
            else if(indexPath.row == 3)
            {
                ct = CellTypeAt;
            }
            else if(indexPath.row == 4)
            {
                ct = CellTypeDays;
            }
            else if(indexPath.row == 5)
            {
                ct = CellTypeSave;
            }
            else if(self.existing)
            {
                ct = CellTypeDelete;
            }
        }
    }
    
    switch(ct)
    {
        case CellTypeType:
        {
            SegmentedSettingCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"SegmentedSettingCell" forIndexPath:indexPath];
            cell.name.text = @"Type";
            cell.control.selectedSegmentIndex = self.single ? 0 : 1;
            
            [cell.control addTarget:self action:@selector(onTypeChanged:) forControlEvents:UIControlEventValueChanged];
            
            return cell;
        }
            
        case CellTypeDate:
        {
            ValueSettingCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"ValueSettingCell" forIndexPath:indexPath];
            cell.name.text = @"Date";
            cell.value.text = [NSDateFormatter localizedStringFromDate:self.start dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
            return cell;
        }
            
        case CellTypeFrom:
        {
            ValueSettingCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"ValueSettingCell" forIndexPath:indexPath];
            cell.name.text = @"Start Date";
            cell.value.text = [NSDateFormatter localizedStringFromDate:self.from dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
            return cell;
        }
            
        case CellTypeTo:
        {
            ValueSettingCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"ValueSettingCell" forIndexPath:indexPath];
            cell.name.text = @"End Date";
            cell.value.text = [NSDateFormatter localizedStringFromDate:self.to dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
            return cell;
        }
            
        case CellTypeAt:
        {
            ValueSettingCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"ValueSettingCell" forIndexPath:indexPath];
            cell.name.text = @"Time";
            cell.value.text = [NSString stringWithFormat:@"%d:%02d", (int)[self.at hour], (int)[self.at minute]];
            return cell;
        }
            
        case CellTypeDays:
        {
            ValueSettingCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"ValueSettingCell" forIndexPath:indexPath];
            cell.name.text = @"Days";
            cell.value.text = [self.days daysString];
            return cell;
        }
            
        case CellTypeSave:
        {
            ButtonSettingCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"ButtonSettingCell" forIndexPath:indexPath];
            [cell.button setTitle:@"Save" forState:UIControlStateNormal];
            return cell;
        }
            
        case CellTypeDelete:
        {
            ButtonSettingCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"ButtonSettingCell" forIndexPath:indexPath];
            [cell.button setTitle:@"Delete" forState:UIControlStateNormal];
            return cell;
        }
    }
    
    return nil;
    
//    ViewScheduleSingleCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ScheduleCell" forIndexPath:indexPath];
//    
//    ScheduleModel* schedule = self.scheduledBroadcasts[indexPath.row];
//    
//    if(schedule.isSingle)
//    {
//        cell.schedule.text = [NSString stringWithFormat:@"Single broadcast %@ %@", [NSDateFormatter localizedStringFromDate:[schedule.start dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], [NSDateFormatter localizedStringFromDate:[schedule.start dateForNumber] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle]];
//    }
//    else
//    {
//    }
//    
//    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (IBAction)onTypeChanged:(id)sender
{
}

@end
