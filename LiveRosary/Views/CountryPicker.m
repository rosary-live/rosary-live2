//
//  CountryPicker.m
//  LiveRosary
//
//  Created by richardtaylor on 4/16/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "CountryPicker.h"
#import "UserManager.h"

@interface CountryPicker() <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, weak) UITextField* textField;
@property (nonatomic, weak) UIView* view;

@end

@implementation CountryPicker

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
    
    [self setCurrent];
}

- (void)setCurrent
{
    if(self.textField.text.length > 0)
    {
        NSString* code = [[UserManager sharedManager] codeForCountryName:self.textField.text];
        if(code.length > 0)
        {
            [self.pickerView selectRow:[[UserManager sharedManager].countryCodes indexOfObject:code] inComponent:0 animated:NO];
        }
    }
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
    return [UserManager sharedManager].countryCodes.count;
}

#pragma mark - UIPickerViewDelegate

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString* code = [[UserManager sharedManager].countryCodes objectAtIndex:row];
    NSString* name = [[UserManager sharedManager] nameForCountryCode:code];
    [self.textField setText:name ];
    [[AnalyticsManager sharedManager] event:@"SetCountry" info:@{@"name": self.textField.text}];
    
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view
{
    UIView* countryView;
    NSString* code = [[UserManager sharedManager].countryCodes objectAtIndex:row];
    UIImage* flagImage = [[UserManager sharedManager] imageForCountryCode:code];
    if(flagImage == nil) NSLog(@"%@ flag missing", code);
    UIImageView* flagImageView;
    UILabel* nameLabel;
    
    if(view != nil)
    {
        countryView = view;
        flagImageView = [countryView.subviews objectAtIndex:0];
        nameLabel = [countryView.subviews objectAtIndex:1];
    }
    else
    {
        CGSize size = [UIScreen mainScreen].bounds.size;
        flagImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, 40, 40)];
        flagImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, size.width - 60, 40)];
        nameLabel.textAlignment = NSTextAlignmentLeft;
        nameLabel.backgroundColor = [UIColor clearColor];
        
        countryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, 40)];
        [countryView insertSubview:flagImageView atIndex:0];
        [countryView insertSubview:nameLabel atIndex:1];
    }
    
    flagImageView.image = flagImage;
    nameLabel.text = [[UserManager sharedManager] nameForCountryCode:code];
    
    return countryView;
}

@end
