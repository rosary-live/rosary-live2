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

@interface LRCreateUserViewController ()

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

@property (nonnull, strong) MBProgressHUD *hud;

@end

@implementation LRCreateUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSArray *arr = [NSLocale preferredLanguages];
    for (NSString *lan in arr) {
        NSLog(@"%@: %@, %@",lan, [NSLocale canonicalLanguageIdentifierFromString:lan], [[[NSLocale alloc] initWithLocaleIdentifier:lan] displayNameForKey:NSLocaleIdentifier value:lan]);
    }
    
    NSLog(@"language codes: %@", [NSLocale ISOLanguageCodes]);
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
                               @"city": @"city",
                               @"state": @"state",
                               @"country": @"country",
                               @"lat": @(38.8520931),
                               @"lon": @(-94.7743856),
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
                [self dismissViewControllerAnimated:YES completion:nil];
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
