//
//  LREditUserViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 3/7/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LREditUserViewController.h"
#import "UserManager.h"
#import "LanguagePicker.h"
#import "CountryPicker.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <FCCurrentLocationGeocoder/FCCurrentLocationGeocoder.h>
#import <CZPhotoPickerController/CZPhotoPickerController.h>

@interface LREditUserViewController ()

@property (nonatomic, weak) IBOutlet UIImageView* avatarImage;
@property (nonatomic, weak) IBOutlet UITextField* firstName;
@property (nonatomic, weak) IBOutlet UITextField* lastName;
@property (nonatomic, weak) IBOutlet UITextField* language;
@property (nonatomic, weak) IBOutlet UITextField* city;
@property (nonatomic, weak) IBOutlet UITextField* state;
@property (nonatomic, weak) IBOutlet UITextField* country;

@property (nonatomic, weak) IBOutlet UIButton* updateAvatarButton;

@property (nonatomic, strong) LanguagePicker* languagePicker;
@property (nonatomic, strong) CountryPicker* countryPicker;

@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) FCCurrentLocationGeocoder* geocoder;
@property (nonatomic) CLLocationDegrees latitude;
@property (nonatomic) CLLocationDegrees longitude;

@property (nonatomic, strong) CZPhotoPickerController* photoPicker;
@property (nonatomic) BOOL havePhoto;

@end

@implementation LREditUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.avatarImage.image = [UserManager sharedManager].avatarImage;
    self.firstName.text = [UserManager sharedManager].currentUser.firstName;
    self.lastName.text = [UserManager sharedManager].currentUser.lastName;
    self.language.text = [UserManager sharedManager].currentUser.language;
    self.city.text = [UserManager sharedManager].currentUser.city;
    self.state.text = [UserManager sharedManager].currentUser.state;
    self.country.text = [UserManager sharedManager].currentUser.country;
    
    self.languagePicker = [[LanguagePicker alloc] initWithTextField:self.language inView:self.view];
    self.countryPicker = [[CountryPicker alloc] initWithTextField:self.country inView:self.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)screenName
{
    return @"Edit User";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onLanguagePickerDone:(id)sender
{
    [self.language resignFirstResponder];
}

- (IBAction)onGPS:(id)sender
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
                    self.country.text = [[UserManager sharedManager] nameForCountryCode:self.geocoder.locationCountryCode];
                    
                    self.latitude = self.geocoder.location.coordinate.latitude;
                    self.longitude = self.geocoder.location.coordinate.longitude;
                    
                    [[AnalyticsManager sharedManager] event:@"EditGeocodeSuccess" info:@{@"City": self.geocoder.locationCity,
                                                                                     @"State": self.geocoder.locationPlacemark.administrativeArea,
                                                                                     @"Country": self.geocoder.locationCountry,
                                                                                     @"CountryCode": self.geocoder.locationCountryCode,
                                                                                     @"Latitude": @(self.geocoder.location.coordinate.latitude),
                                                                                     @"Longitude": @(self.geocoder.location.coordinate.longitude)}];
                    
                    [self.countryPicker setCurrent];
                }
                else
                {
                    [[AnalyticsManager sharedManager] event:@"EditGeocodeError" info:nil];
                    [self showLocationError];
                }
            });
        }];
    }
    else
    {
        [[AnalyticsManager sharedManager] event:@"EditNoGeocode" info:nil];
        [self showLocationError];
    }
}

- (void)showLocationError
{
    [UIAlertView bk_showAlertViewWithTitle:nil message:@"We were unable to determine your location." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
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
    
    [[AnalyticsManager sharedManager] event:@"UpdateAvatar" info:nil];

}

- (IBAction)onSave:(id)sender
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
    
    if(validationErrorMsg != nil)
    {
        [UIAlertView bk_showAlertViewWithTitle:@"Validation Error" message:validationErrorMsg cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
        return;
    }
    
    NSDictionary* settings = @{
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
    self.hud.labelText = @"Updating User";
    [[UserManager sharedManager] updateUserInfoWithDictionary:settings completion:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.hud hide:YES];
            
            if(error != nil)
            {
                DDLogError(@"Error creating new user %@: %@", settings, error);
                [[AnalyticsManager sharedManager] error:error name:@"UpdateUser"];

                [UIAlertView bk_showAlertViewWithTitle:@"Error" message:@"Error updating user." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
            }
            else
            {
                [[AnalyticsManager sharedManager] event:@"UpdateUser" info:nil];

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
                                [[AnalyticsManager sharedManager] error:error name:@"UpdateUploadAvatarImage"];

                                [UIAlertView bk_showAlertViewWithTitle:@"Error" message:@"Error updating photo." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
                            }
                            else
                            {
                                [[AnalyticsManager sharedManager] event:@"UpdateUploadAvatarImage" info:nil];

                                [self.navigationController popViewControllerAnimated:YES];
                            }
                        });
                    }];
                }
                else
                {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
        });
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
    return YES;
}

@end
