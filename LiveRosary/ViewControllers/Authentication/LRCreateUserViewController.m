//
//  LRCreateUserViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/31/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRCreateUserViewController.h"
#import "UserManager.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <FCCurrentLocationGeocoder/FCCurrentLocationGeocoder.h>
#import <CZPhotoPickerController/CZPhotoPickerController.h>

@interface LRCreateUserViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, weak) IBOutlet UITextField* firstName;
@property (nonatomic, weak) IBOutlet UITextField* lastName;
@property (nonatomic, weak) IBOutlet UITextField* email;
@property (nonatomic, weak) IBOutlet UITextField* password;
@property (nonatomic, weak) IBOutlet UITextField* verifyPassword;
@property (nonatomic, weak) IBOutlet UITextField* city;
@property (nonatomic, weak) IBOutlet UITextField* state;
@property (nonatomic, weak) IBOutlet UITextField* country;
@property (nonatomic, weak) IBOutlet UITextField* language;
@property (nonatomic, weak) IBOutlet UIImageView* avatarImage;

@property (nonatomic, weak) IBOutlet UIButton* updateAvatarButton;

@property (nonatomic, strong) UIPickerView* languagePickerView;

@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) FCCurrentLocationGeocoder* geocoder;
@property (nonatomic) CLLocationDegrees latitude;
@property (nonatomic) CLLocationDegrees longitude;

@property (nonatomic, strong) NSString* languageCode;
@property (nonatomic, strong) NSString* languageName;

@property (nonatomic, strong) CZPhotoPickerController* photoPicker;
@property (nonatomic) BOOL havePhoto;

@end

@implementation LRCreateUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self populateLanguage];
    [self populateLocation];
    [self addLanguagePickerView];
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

- (void)populateLanguage
{
    NSArray* languages = [NSLocale preferredLanguages];
    if(languages != nil && languages.count > 0)
    {
        NSString* code = languages[0];
        self.languageCode = [code componentsSeparatedByString:@"-"][0];
        self.languageName = [[[NSLocale alloc] initWithLocaleIdentifier:self.languageCode] displayNameForKey:NSLocaleIdentifier value:self.languageCode];
        self.language.text = self.languageName;
    }    
}

- (void)populateLocation
{
    self.latitude = 0.0;
    self.longitude = 0.0;
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = @"Determining Location";
    
    if([[FCCurrentLocationGeocoder sharedGeocoder] canGeocode])
    {
        self.geocoder = [FCCurrentLocationGeocoder new];
        self.geocoder.canPromptForAuthorization = YES;
        self.geocoder.canUseIPAddressAsFallback = YES;
        self.geocoder.timeFilter = 30;
        self.geocoder.timeoutErrorDelay = 10;
        
        [self.geocoder reverseGeocode:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.hud hide:YES];
                
                if(success)
                {
                    self.city.text = self.geocoder.locationCity;
                    self.state.text = self.geocoder.locationPlacemark.administrativeArea;
                    self.country.text = self.geocoder.locationCountry;
                    
                    self.latitude = self.geocoder.location.coordinate.latitude;
                    self.longitude = self.geocoder.location.coordinate.longitude;
                }
                else
                {
                    [UIAlertView bk_showAlertViewWithTitle:nil message:@"We were unable to determine your location." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
                }
            });
        }];
    }
}

-(void)addLanguagePickerView
{
    self.languagePickerView = [[UIPickerView alloc] init];
    self.languagePickerView.dataSource = self;
    self.languagePickerView.delegate = self;
    self.languagePickerView.showsSelectionIndicator = YES;
    
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Done" style:UIBarButtonItemStyleDone
                                   target:self action:@selector(onLanguagePickerDone:)];
    
    UIToolbar* toolBar = [[UIToolbar alloc] initWithFrame:
                          CGRectMake(0, self.view.frame.size.height-
                                     self.languagePickerView.frame.size.height-50, 320, 50)];
    
    [toolBar setBarStyle:UIBarStyleBlackOpaque];
    NSArray *toolbarItems = [NSArray arrayWithObjects:doneButton, nil];
    [toolBar setItems:toolbarItems];
    self.language.inputView = self.languagePickerView;
    self.language.inputAccessoryView = toolBar;
    
    [self.languagePickerView selectRow:[[UserManager sharedManager].languages indexOfObject:self.language.text] inComponent:0 animated:NO];
}

- (IBAction)onLanguagePickerDone:(id)sender
{
    [self.language resignFirstResponder];
}

- (IBAction)onCreate:(id)sender
{
    NSString* validationErrorMsg = nil;
    
    if(self.firstName.text.length == 0)
    {
        validationErrorMsg = @"First Name is required.";
    }
    else if(self.lastName.text.length == 0)
    {
        validationErrorMsg = @"Last Name is required.";
    }
    else if(self.email.text.length == 0)
    {
        validationErrorMsg = @"Email address is required.";
    }
    else if(![self.email.text validEmailAddress])
    {
        validationErrorMsg = @"Valid email address is required.";
    }
    else if(self.password.text.length < 6)
    {
        validationErrorMsg = @"Password with at least 6 characters is required.";
    }
    else if(![self.password.text isEqualToString:self.verifyPassword.text])
    {
        validationErrorMsg = @"Passwords must match.";
    }
    
    if(validationErrorMsg != nil)
    {
        [UIAlertView bk_showAlertViewWithTitle:@"Validation Error" message:validationErrorMsg cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
        return;
    }
    
    NSDictionary* settings = @{
                               @"email": self.email.text,
                               @"password": self.password.text,
                               @"firstName": self.firstName.text,
                               @"lastName": self.lastName.text,
                               @"city": self.city.text,
                               @"state": self.state.text,
                               @"country": self.country.text,
                               @"language": self.language.text,
                               @"avatar": @(self.havePhoto ? 1 : 0),
                               @"lat": @(self.latitude),
                               @"lon": @(self.longitude),
                               };
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = @"Creating User";
    [[UserManager sharedManager] createUserWithDictionary:settings completion:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.hud hide:YES];
            
            if(error != nil)
            {
                DDLogError(@"Error creating new user %@: %@", settings, error);
                [UIAlertView bk_showAlertViewWithTitle:@"Error" message:@"Error creating user." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
            }
            else
            {
                if(self.havePhoto)
                {
                    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    self.hud.labelText = @"Uploading Photo";
                    
                    [[UserManager sharedManager] uploadAvatarImage:self.avatarImage.image completion:^(NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.hud hide:YES];
                            
                            if(error != nil)
                            {
                                DDLogError(@"Error uploading avatar image: %@", error);
                                [UIAlertView bk_showAlertViewWithTitle:@"Error" message:@"Error uploading photo." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
                            }
                            else
                            {
                                [self dismissViewControllerAnimated:YES completion:nil];
                            }
                        });
                    }];
                }
                else
                {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            }
        });
    }];
}

- (IBAction)onUpdateAvatar:(id)sender
{
    [self.view endEditing:YES];
    
    @weakify(self);    
    self.photoPicker = [[CZPhotoPickerController alloc] initWithPresentingViewController:self withCompletionBlock:^(UIImagePickerController *imagePickerController, NSDictionary *imageInfoDict) {
        
        @strongify(self);
        
        if(imageInfoDict != nil)
        {
            if (imagePickerController.allowsEditing) {
                self.avatarImage.image = imageInfoDict[UIImagePickerControllerEditedImage];
            }
            else {
                self.avatarImage.image = imageInfoDict[UIImagePickerControllerOriginalImage];
            }
            
            self.havePhoto = YES;
        }
        
        [self.photoPicker dismissAnimated:YES];
        self.photoPicker = nil;
        
    }];
    
    self.photoPicker.allowsEditing = YES;
    self.photoPicker.cropOverlaySize = CGSizeMake(500, 500); // optional
    [self.photoPicker showFromRect:self.updateAvatarButton.frame];
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
    return YES;
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
    [self.language setText:[[UserManager sharedManager].languages objectAtIndex:row]];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[UserManager sharedManager].languages objectAtIndex:row];
}

@end
