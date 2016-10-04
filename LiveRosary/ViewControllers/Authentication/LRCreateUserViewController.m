//
//  LRCreateUserViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/31/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRCreateUserViewController.h"
#import "UserManager.h"
#import "LanguagePicker.h"
#import "CountryPicker.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <FCCurrentLocationGeocoder/FCCurrentLocationGeocoder.h>
#import <CZPhotoPickerController/CZPhotoPickerController.h>

@interface LRCreateUserViewController ()

@property (nonatomic, weak) IBOutlet UILabel* header;

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

@property (nonatomic, strong) LanguagePicker* languagePicker;
@property (nonatomic, strong) CountryPicker* countryPicker;

@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) FCCurrentLocationGeocoder* geocoder;
@property (nonatomic) CLLocationDegrees latitude;
@property (nonatomic) CLLocationDegrees longitude;
@property (nonatomic) BOOL gotLocation;

@property (nonatomic, strong) CZPhotoPickerController* photoPicker;
@property (nonatomic) BOOL havePhoto;

@end

@implementation LRCreateUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.header.font = [UIFont fontWithName:@"Rokkitt" size:26.0f];

    [self populateLanguage];
    [self populateLocation];
    
    self.languagePicker = [[LanguagePicker alloc] initWithTextField:self.language inView:self.view];
    self.countryPicker = [[CountryPicker alloc] initWithTextField:self.country inView:self.view];    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)screenName
{
    return @"Create User";
}

- (BOOL)hideNavBar {
    return YES;
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
        NSString* languageCode = [code componentsSeparatedByString:@"-"][0];
        NSString* languageName = [[[NSLocale alloc] initWithLocaleIdentifier:languageCode] displayNameForKey:NSLocaleIdentifier value:languageCode];
        self.language.text = languageName;
    }    
}

- (void)populateLocation
{
//    self.latitude = 0.0;
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
                    self.gotLocation = YES;
                    
                    [[AnalyticsManager sharedManager] event:@"CreateGeocodeSuccess" info:@{@"City": self.geocoder.locationCity,
                                                                                         @"State": self.geocoder.locationPlacemark.administrativeArea,
                                                                                         @"Country": self.geocoder.locationCountry,
                                                                                         @"CountryCode": self.geocoder.locationCountryCode,
                                                                                         @"Latitude": @(self.geocoder.location.coordinate.latitude),
                                                                                         @"Longitude": @(self.geocoder.location.coordinate.longitude)}];
                    
                    [self.countryPicker setCurrent];
                }
                else
                {
                    [[AnalyticsManager sharedManager] event:@"CreateGeocodeError" info:nil];

                    [UIAlertView bk_showAlertViewWithTitle:nil message:@"We were unable to determine your location." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
                }
            });
        }];
    }
    else
    {
        [[AnalyticsManager sharedManager] event:@"CreateNoGeocode" info:nil];
    }
}

- (IBAction)onGPS:(id)sender {
    [self populateLocation];
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
    else if(self.city.text.length == 0)
    {
        validationErrorMsg = @"City is required.";
    }
    else if(self.state.text.length == 0)
    {
        validationErrorMsg = @"State is required.";
    }
    else if(self.country.text.length == 0)
    {
        validationErrorMsg = @"Country is required.";
    }
    
    if(validationErrorMsg != nil)
    {
        [UIAlertView bk_showAlertViewWithTitle:@"Validation Error" message:validationErrorMsg cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
        return;
    }
    
    if(self.gotLocation) {
        [self createUser];
    } else {
        NSString* address = [NSString stringWithFormat:@"%@, %@, %@", self.city.text, self.state.text, self.country.text];
        [[[CLGeocoder alloc] init] geocodeAddressString:address completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            if(placemarks.count > 0) {
                CLLocation* location = placemarks[0].location;
                if(location != nil) {
                    self.gotLocation = YES;
                    self.latitude = location.coordinate.latitude;
                    self.longitude = location.coordinate.longitude;
                }
            }
            
            [self createUser];
        }];
    }
}

- (void)createUser {
    NSDictionary* settings = @{
                               @"email": [self.email.text lowercaseString],
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
                [[AnalyticsManager sharedManager] error:error name:@"CreateUser"];
                
                [UIAlertView bk_showAlertViewWithTitle:@"Error" message:@"Error creating user." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_NOTIFICATION_NAME object:nil];
                [[AnalyticsManager sharedManager] event:@"CreateUser" info:nil];
                
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
                                [[AnalyticsManager sharedManager] error:error name:@"CreateUploadAvatar"];
                                
                                [UIAlertView bk_showAlertViewWithTitle:@"Error" message:@"Error uploading photo." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
                            }
                            else
                            {
                                [[AnalyticsManager sharedManager] event:@"CreateUploadAvatarImage" info:nil];
                                
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

@end
