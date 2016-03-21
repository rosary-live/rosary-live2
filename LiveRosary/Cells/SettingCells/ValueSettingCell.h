//
//  ValueSettingCell.h
//  LiveRosary
//
//  Created by richardtaylor on 3/20/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "SettingCell.h"

typedef void(^ValueChangedBlock)(NSDate* value);

@interface ValueSettingCell : SettingCell

@property (nonatomic, weak) IBOutlet UILabel* value;
@property (nonatomic, strong) UIDatePicker* datePicker;

- (CGFloat)addDatePickerWithDate:(NSDate*)date andMode:(UIDatePickerMode)mode valueChanged:(ValueChangedBlock)changed;
- (void)removeDatePicker;

@end
