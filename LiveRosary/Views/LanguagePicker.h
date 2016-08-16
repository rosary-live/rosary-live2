//
//  LanguagePicker.h
//  LiveRosary
//
//  Created by richardtaylor on 4/16/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LanguagePicker : NSObject

@property (nonatomic, strong) UIPickerView* pickerView;

- (instancetype)initWithTextField:(UITextField*)textField inView:(UIView*)view;

@end
