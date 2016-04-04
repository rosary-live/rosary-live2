//
//  LRResetPasswordViewController.m
//  LiveRosary
//
//  Created by Richard Taylor on 3/31/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRResetPasswordViewController.h"
#import "UserManager.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface LRResetPasswordViewController ()

@property (nonatomic, weak) IBOutlet UITextField* updatedPassword;
@property (nonatomic, weak) IBOutlet UITextField* verifyPassword;

@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation LRResetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)screenName
{
    return @"Reset Password";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onReset:(id)sender
{
    NSString* validationErrorMsg = nil;
    
    if(self.updatedPassword.text.length < 6)
    {
        validationErrorMsg = @"Password with at least 6 characters is required.";
    }
    else if(![self.updatedPassword.text isEqualToString:self.verifyPassword.text])
    {
        validationErrorMsg = @"Passwords must match.";
    }
    
    if(validationErrorMsg != nil)
    {
        [UIAlertView bk_showAlertViewWithTitle:@"Validation Error" message:validationErrorMsg cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
        return;
    }
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = @"Resetting Password";
    
    [[UserManager sharedManager] resetPassword:self.updatedPassword.text completion:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.hud hide:YES];
            
            if(error != nil)
            {
                DDLogError(@"Error resetting password: %@", error);
                [[AnalyticsManager sharedManager] error:error name:@"ResetPassword"];

                [UIAlertView bk_showAlertViewWithTitle:@"Error" message:@"Unabled to reset password." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
            }
            else
            {
                [[AnalyticsManager sharedManager] event:@"ResetPassword" info:nil];

                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        });
    }];
}

@end
