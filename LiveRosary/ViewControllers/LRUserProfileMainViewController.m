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

@end

@implementation LRUserProfileMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addDrawerButton];

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

- (IBAction)onLogout:(id)sender
{
    [[UserManager sharedManager] logoutWithCompletion:^(NSError *error) {
        DDLogInfo(@"Logout complete");
    }];
}

@end
