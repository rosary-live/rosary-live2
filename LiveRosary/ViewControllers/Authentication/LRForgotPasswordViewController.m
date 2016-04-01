//
//  LRForgotPasswordViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/31/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRForgotPasswordViewController.h"
#import "BranchUniversalObject.h"
#import "BranchLinkProperties.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface LRForgotPasswordViewController ()

@property (nonatomic, weak) IBOutlet UITextField* email;
@property (nonatomic, weak) IBOutlet UILabel* instructions;

@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation LRForgotPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
    return YES;
}

- (IBAction)onReset:(id)sender
{
    if(self.email.text.length == 0)
    {
        [UIAlertView bk_showAlertViewWithTitle:@"Error" message:@"You must the email address of your LiveRosary account." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
        return;
    }
    
    BranchUniversalObject *branchUniversalObject = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:[NSString stringWithFormat:@"LostPassword/%@", self.email.text]];
    branchUniversalObject.title = @"Reset Password";
    branchUniversalObject.contentDescription = [NSString stringWithFormat:@"LiveRosary reset password for %@", self.email.text];
    //branchUniversalObject.imageUrl = @"https://example.com/mycontent-12345.png";
    [branchUniversalObject addMetadataKey:@"email" value:self.email.text];
    
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = @"Requesting Password Reset";
    
    [branchUniversalObject getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString *url, NSError *error) {
        if(error != nil)
        {
            [self.hud hide:YES];
            [UIAlertView bk_showAlertViewWithTitle:@"Error" message:@"Unable to report broadcast." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
        }
        else
        {
            NSLog(@"success getting url! %@", url);
        }
        
        NSString* name = [NSString stringWithFormat:@"%@ %@", [UserManager sharedManager].currentUser.firstName, [UserManager sharedManager].currentUser.lastName];
        [[LiveRosaryService sharedService] reportBroadcast:self.broadcast reporterName:name reporterEmail:[UserManager sharedManager].email reason:self.reason.text link:url completion:^(NSError *error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.hud hide:YES];
                
                if(error != nil)
                {
                    [UIAlertView bk_showAlertViewWithTitle:@"Error" message:@"Unable to report broadcast." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
                }
                else
                {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            });
        }];
    }];}

@end
