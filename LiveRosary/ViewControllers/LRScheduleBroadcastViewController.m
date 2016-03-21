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
    CellTypeNone,
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

@property (nonatomic, strong) UISegmentedControl* typeControl;

@property (nonatomic) BOOL existing;
@property (nonatomic) BOOL single;
@property (nonatomic, strong) NSDate* start;
@property (nonatomic, strong) NSDate* from;
@property (nonatomic, strong) NSDate* to;
@property (nonatomic, strong) NSNumber* at;
@property (nonatomic, strong) NSNumber* days;

@property (nonatomic) CellType expandedCell;
@property (nonatomic, strong) NSIndexPath* expandedCellIndexPath;
@property (nonatomic) CGFloat expandedCellHeight;

@end

@implementation LRScheduleBroadcastViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.expandedCell = CellTypeNone;
    
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

- (CellType)typeAtRow:(NSInteger)row
{
    CellType ct;
    
    if(row == 0)
    {
        ct = CellTypeType;
    }
    else
    {
        if(self.single)
        {
            if(row == 1)
            {
                ct = CellTypeDate;
            }
            else if(row == 2)
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
            if(row == 1)
            {
                ct = CellTypeFrom;
            }
            else if(row == 2)
            {
                ct = CellTypeTo;
            }
            else if(row == 3)
            {
                ct = CellTypeAt;
            }
            else if(row == 4)
            {
                ct = CellTypeDays;
            }
            else if(row == 5)
            {
                ct = CellTypeSave;
            }
            else if(self.existing)
            {
                ct = CellTypeDelete;
            }
        }
    }
    
    return ct;
}

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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([self typeAtRow:indexPath.row] == self.expandedCell)
    {
        return self.expandedCellHeight;
    }
    
    return 50.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CellType ct = [self typeAtRow:indexPath.row];
    
    switch(ct)
    {
        case CellTypeType:
        {
            SegmentedSettingCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"SegmentedSettingCell" forIndexPath:indexPath];
            cell.name.text = @"Type";
            cell.control.selectedSegmentIndex = self.single ? 0 : 1;
            
            self.typeControl = cell.control;
            
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
            [cell.button addTarget:self action:@selector(onSave:) forControlEvents:UIControlEventTouchUpInside];
            return cell;
        }
            
        case CellTypeDelete:
        {
            ButtonSettingCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"ButtonSettingCell" forIndexPath:indexPath];
            [cell.button setTitle:@"Delete" forState:UIControlStateNormal];
            [cell.button addTarget:self action:@selector(onDelete:) forControlEvents:UIControlEventTouchUpInside];
            return cell;
        }
    }
    
    return nil;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SettingCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    if(cell.expandable)
    {
        ValueSettingCell* cell = [tableView cellForRowAtIndexPath:indexPath];
        CellType ct = [self typeAtRow:indexPath.row];
        if(ct == self.expandedCell)
        {
            [cell removeDatePicker];
            self.expandedCell = CellTypeNone;
            self.expandedCellIndexPath = nil;
            
            [tableView reloadData];
            return;
        }
        
        if(self.expandedCell != CellTypeNone)
        {
            ValueSettingCell* exCell = [tableView cellForRowAtIndexPath:self.expandedCellIndexPath];
            [exCell removeDatePicker];
            self.expandedCell = CellTypeNone;
            self.expandedCellIndexPath = nil;
        }
        
        __weak ValueSettingCell* weakCell = cell;
        self.expandedCellIndexPath = indexPath;
        self.expandedCell = ct;
        self.expandedCellHeight = [cell addDatePickerWithDate:[NSDate date] andMode:UIDatePickerModeDate valueChanged:^(NSDate *value) {
            self.start = value;
            weakCell.value.text = [NSDateFormatter localizedStringFromDate:self.start dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
        }];
    }
    
//    if(ct == CellTypeDate)
//    {
//        self.dateExpanded = !self.dateExpanded;
//        
//        ValueSettingCell* cell = [tableView cellForRowAtIndexPath:indexPath];
//        if(self.dateExpanded)
//        {
//            __weak ValueSettingCell* weakCell = cell;
//            self.dateExpandedHeight = [cell addDatePickerWithDate:[NSDate date] andMode:UIDatePickerModeDate valueChanged:^(NSDate *value) {
//                self.start = value;
//                weakCell.value.text = [NSDateFormatter localizedStringFromDate:self.start dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
//            }];
//        }
//        else
//        {
//            [cell removeDatePicker];
//        }
//    }
    
    [tableView reloadData];
}

- (IBAction)onTypeChanged:(id)sender
{
    self.single = self.typeControl.selectedSegmentIndex == 0;
    [self.tableView reloadData];
}

- (IBAction)onSave:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onDelete:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
