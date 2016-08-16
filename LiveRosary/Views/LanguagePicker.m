//
//  LanguagePicker.m
//  LiveRosary
//
//  Created by richardtaylor on 4/16/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LanguagePicker.h"
#import "UserManager.h"

@interface LanguagePicker() <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, weak) UITextField* textField;
@property (nonatomic, weak) UIView* view;

@end

@implementation LanguagePicker

- (instancetype)initWithTextField:(UITextField*)textField inView:(UIView*)view
{
    self = [super init];
    if(self != nil)
    {
        self.textField = textField;
        [self addPickerView];
    }
    
    return self;
}

-(void)addPickerView
{
    self.pickerView = [[UIPickerView alloc] init];
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    self.pickerView.showsSelectionIndicator = YES;
    
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Done" style:UIBarButtonItemStyleDone
                                   target:self action:@selector(onPickerDone:)];
    
    UIToolbar* toolBar = [[UIToolbar alloc] initWithFrame:
                          CGRectMake(0, self.view.frame.size.height - self.pickerView.frame.size.height - 50, 320, 50)];
    
    [toolBar setBarStyle:UIBarStyleBlackOpaque];
    NSArray *toolbarItems = [NSArray arrayWithObjects:doneButton, nil];
    [toolBar setItems:toolbarItems];
    self.textField.inputView = self.pickerView;
    self.textField.inputAccessoryView = toolBar;
    
    [self.pickerView selectRow:[[UserManager sharedManager].languages indexOfObject:self.textField.text] inComponent:0 animated:NO];
}

- (IBAction)onPickerDone:(id)sender
{
    [self.textField resignFirstResponder];
}

#pragma mark - UIPickerViewDataSource

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [UserManager sharedManager].languages.count;
}

#pragma mark - UIPickerViewDelegate

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self.textField setText:[[UserManager sharedManager].languages objectAtIndex:row]];
    [[AnalyticsManager sharedManager] event:@"SetLanguage" info:@{@"name": self.textField.text}];
    
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[UserManager sharedManager].languages objectAtIndex:row];
}

//- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view
//{
//}

@end
