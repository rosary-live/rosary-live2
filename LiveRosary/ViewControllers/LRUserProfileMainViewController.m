//
//  LRUserProfileViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRUserProfileMainViewController.h"
#import "UserManager.h"

@interface LRUserProfileMainViewController ()

@property (nonatomic, weak) IBOutlet UILabel* email;
@property (nonatomic, weak) IBOutlet UIImageView* avatar;
@property (nonatomic, weak) IBOutlet UILabel* firstName;
@property (nonatomic, weak) IBOutlet UILabel* lastName;
@property (nonatomic, weak) IBOutlet UILabel* language;
@property (nonatomic, weak) IBOutlet UILabel* city;
@property (nonatomic, weak) IBOutlet UILabel* state;
@property (nonatomic, weak) IBOutlet UILabel* country;

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

- (IBAction)onLogout:(id)sender
{
    [[UserManager sharedManager] logoutWithCompletion:^(NSError *error) {
        DDLogInfo(@"Logout complete");
        [[AnalyticsManager sharedManager] event:@"LoggedOut" info:nil];
    }];
}

@end
