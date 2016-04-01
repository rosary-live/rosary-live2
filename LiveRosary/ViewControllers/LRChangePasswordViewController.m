//
//  LRChangePasswordViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 3/7/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRChangePasswordViewController.h"
#import "UserManager.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface LRChangePasswordViewController ()

@property (nonatomic, weak) IBOutlet UITextField* currentPassword;
@property (nonatomic, weak) IBOutlet UITextField* updatedPassword;
@property (nonatomic, weak) IBOutlet UITextField* verifyPassword;

@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation LRChangePasswordViewController

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
    return @"Change Password";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onChange:(id)sender
{
    NSString* validationErrorMsg = nil;

    if(self.currentPassword.text.length == 0)
    {
        validationErrorMsg = @"Current password is required.";
    }
    else if(self.updatedPassword.text.length < 6)
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
    self.hud.labelText = @"Changing Password";
    
    [[UserManager sharedManager] changePassword:self.currentPassword.text newPassword:self.updatedPassword.text completion:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.hud hide:YES];
            
            if(error != nil)
            {
                DDLogError(@"Error updating password: %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Error" message:@"Unabled to change password." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
            }
            else
            {
                [self.navigationController popViewControllerAnimated:YES];
            }
        });
    }];
}

@end
