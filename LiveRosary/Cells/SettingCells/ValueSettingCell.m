//
//  ValueSettingCell.m
//  LiveRosary
//
//  Created by richardtaylor on 3/20/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "ValueSettingCell.h"

@interface ValueSettingCell ()

@property (nonatomic, strong) ValueChangedBlock valueChanged;

@end

@implementation ValueSettingCell

- (CGFloat)addDatePickerWithDate:(NSDate*)date andMode:(UIDatePickerMode)mode valueChanged:(ValueChangedBlock)changed
{
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.frame = CGRectMake(0.0, 50.0, self.frame.size.width, self.datePicker.frame.size.height);
    self.datePicker.datePickerMode = mode;
    self.datePicker.date = date;
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

- (BOOL)expandable
{
    return YES;
}

@end
