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

@property (nonatomic, weak) IBOutlet UITextField* email;
@property (nonatomic, weak) IBOutlet UITextField* password;

@end

@implementation LRCreateUserViewController

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

- (IBAction)onCreate:(id)sender
{
    [[UserManager sharedManager] createUserWithEmail:self.email.text password:self.password.text completion:^(NSError *error) {
        NSLog(@"error: %@", error);
    }];
}

@end
