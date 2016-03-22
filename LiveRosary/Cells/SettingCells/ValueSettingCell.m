//
//  ValueSettingCell.m
//  LiveRosary
//
//  Created by richardtaylor on 3/20/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "ValueSettingCell.h"
#import "NSNumber+Utilities.h"

@interface ValueSettingCell ()

@property (nonatomic, strong) ValueChangedBlock valueChanged;

@end

@implementation ValueSettingCell

- (CGFloat)addDatePickerWithDate:(NSDate*)date mode:(UIDatePickerMode)mode minDate:(NSDate*)minDate maxDate:(NSDate*)maxDate minuteInterval:(NSInteger)minuteInterval valueChanged:(ValueChangedBlock)changed
{
    [self removeDatePicker];
    
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.frame = CGRectMake(0.0, 50.0, self.frame.size.width, self.datePicker.frame.size.height);
    self.datePicker.datePickerMode = mode;
    self.datePicker.date = date;
    if(minDate != nil) self.datePicker.minimumDate = minDate;
    if(maxDate != nil) self.datePicker.maximumDate = maxDate;
    if(minuteInterval > 0) self.datePicker.minuteInterval = minuteInterval;
    [self addSubview:self.datePicker];
    self.valueChanged = changed;
    [self.datePicker addTarget:self action:@selector(onDatePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    return self.datePicker.frame.size.height + 50.0;
}

- (void)removeDatePicker
{
    if(self.datePicker != nil)
    {
        [self.datePicker removeFromSuperview];
        self.datePicker = nil;
    }
}

- (IBAction)onDatePickerValueChanged:(id)sender
{
    if(self.valueChanged != nil)
    {
        self.valueChanged(self.datePicker.date);
    }
}

- (CGFloat)addDayPickerWithDays:(NSNumber*)days valueChanged:(ValueChangedBlock)changed
{
    [self removeDayPicker];
    
    self.dayPicker = [[THSegmentedControl alloc] initWithSegments:@[ @"Su", @"M", @"Tu", @"W", @"Th", @"F", @"Sa" ]];
    self.dayPicker.frame = CGRectMake(0.0, 50.0, self.frame.size.width, 50.0);
    [self addSubview:self.dayPicker];
    self.valueChanged = changed;
    
    NSMutableOrderedSet* daySet = [NSMutableOrderedSet new];
    for(Day day = 0; day < 7; day++)
    {
        if([days dayOn:day])
        {
            [daySet addObject:@(day)];
        }
    }
    
    self.dayPicker.selectedIndexes = daySet;
    
    [self.dayPicker addTarget:self action:@selector(onDayPickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    return 50.0 + 50.0;
}

- (void)removeDayPicker
{
    if(self.dayPicker != nil)
    {
        [self.dayPicker removeFromSuperview];
        self.dayPicker = nil;
    }
}

- (IBAction)onDayPickerValueChanged:(id)sender
{
    if(self.valueChanged != nil)
    {
        NSNumber* val = @(0);
        
        NSOrderedSet* set = self.dayPicker.selectedIndexes;
        for(NSNumber* dayIndex in self.dayPicker.selectedIndexes)
        {
            val = [val numberWithDayOn:dayIndex.integerValue];
        }
        
        self.valueChanged(val);
    }
}

- (BOOL)expandable
{
    return YES;
}

@end
