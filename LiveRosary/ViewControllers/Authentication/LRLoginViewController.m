//
//  LRLoginViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/31/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRLoginViewController.h"
#import "UserManager.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface LRLoginViewController ()

@property (nonatomic, weak) IBOutlet UILabel* header;

@property (nonatomic, weak) IBOutlet UITextField* email;
@property (nonatomic, weak) IBOutlet UITextField* password;

@property (nonnull, strong) MBProgressHUD *hud;

@end

@implementation LRLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.header.font = [UIFont fontWithName:@"Rokkitt" size:26.0f];
}

- (NSString*)screenName
{
    return @"Login";
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

- (IBAction)onLogin:(id)sender
{
    NSString* validationErrorMsg = nil;
    
    if(self.email.text.length == 0)
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
    
    if(validationErrorMsg != nil)
    {
        [UIAlertView bk_showAlertViewWithTitle:@"Validation Error" message:validationErrorMsg cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
        return;
    }
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = @"Logging In";
    [[UserManager sharedManager] loginWithEmail:[self.email.text lowercaseString] password:self.password.text completion:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.hud hide:YES];
            
            if(error != nil)
            {
                [[AnalyticsManager sharedManager] error:error name:@"UserLogin"];

                [UIAlertView bk_showAlertViewWithTitle:@"Error" message:error.localizedDescription cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_NOTIFICATION_NAME object:nil];

                [[AnalyticsManager sharedManager] event:@"UserLogin" info:nil];
                
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        });
    }];
}

- (IBAction)onBak:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
    return YES;
}

@end
