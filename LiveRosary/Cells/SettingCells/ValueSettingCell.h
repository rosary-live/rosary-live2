//
//  ValueSettingCell.h
//  LiveRosary
//
//  Created by richardtaylor on 3/20/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "SettingCell.h"
#import <THSegmentedControl/THSegmentedControl.h>

typedef void(^ValueChangedBlock)(id value);

@interface ValueSettingCell : SettingCell

@property (nonatomic, weak) IBOutlet UILabel* value;

@property (nonatomic, strong) UIDatePicker* datePicker;
@property (nonatomic, strong) THSegmentedControl* dayPicker;

- (CGFloat)addDatePickerWithDate:(NSDate*)date mode:(UIDatePickerMode)mode minDate:(NSDate*)minDate maxDate:(NSDate*)maxDate minuteInterval:(NSInteger)minuteInterval valueChanged:(ValueChangedBlock)changed;
- (void)removeDatePicker;

- (CGFloat)addDayPickerWithDays:(NSNumber*)days valueChanged:(ValueChangedBlock)changed;
- (void)removeDayPicker;

@end
