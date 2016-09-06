//
//  LRUserProfileViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRUserProfileMainViewController.h"
#import "UserManager.h"
#import "LiveRosaryService.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface LRUserProfileMainViewController ()

@property (nonatomic, weak) IBOutlet UILabel* email;
@property (nonatomic, weak) IBOutlet UIImageView* avatar;
@property (nonatomic, weak) IBOutlet UILabel* firstName;
@property (nonatomic, weak) IBOutlet UILabel* lastName;
@property (nonatomic, weak) IBOutlet UILabel* language;
@property (nonatomic, weak) IBOutlet UILabel* city;
@property (nonatomic, weak) IBOutlet UILabel* state;
@property (nonatomic, weak) IBOutlet UILabel* country;

@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation LRUserProfileMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addDrawerButton];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.email.text = [UserManager sharedManager].currentUser.email;
    self.avatar.image = [UserManager sharedManager].avatarImage;
    self.firstName.text = [UserManager sharedManager].currentUser.firstName;
    self.lastName.text = [UserManager sharedManager].currentUser.lastName;
    self.language.text = [UserManager sharedManager].currentUser.language;
    self.city.text = [UserManager sharedManager].currentUser.city;
    self.state.text = [UserManager sharedManager].currentUser.state;
    self.country.text = [UserManager sharedManager].currentUser.country;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)screenName
{
    return @"User Profile";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onBroadcastRequest:(id)sender {
    UIAlertController* intentionAlert = [UIAlertController alertControllerWithTitle:nil message:@"Enter your reason for requesting broadcast permission." preferredStyle:UIAlertControllerStyleAlert];
    
    [intentionAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Reason";
    }];
    
    [intentionAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString* reason = intentionAlert.textFields.firstObject.text;
        reason = reason != nil ? reason : @"";
        [[AnalyticsManager sharedManager] event:@"RequestBroadcastPermission" info:@{@"user": [UserManager sharedManager].email, @"Reason": reason}];

        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.labelText = @"Sending Request";
        [[LiveRosaryService sharedService] requestBroadcastPermissionWithReason:reason completion:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.hud hide:YES];
                
                if(error != nil) {
                    [UIAlertView bk_showAlertViewWithTitle:nil message:@"Error sending request." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
                }
            });
        }];
    }]];
    
    [self presentViewController:intentionAlert animated:YES completion:nil];
}

- (IBAction)onLogout:(id)sender
{
    [[UserManager sharedManager] logoutWithCompletion:^(NSError *error) {
        DDLogInfo(@"Logout complete");
        [[AnalyticsManager sharedManager] event:@"LoggedOut" info:nil];
    }];
}

@end
