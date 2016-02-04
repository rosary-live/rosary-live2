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

@property (nonatomic, weak) IBOutlet UITextField* email;
@property (nonatomic, weak) IBOutlet UITextField* password;

@end

@implementation LRLoginViewController

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

- (IBAction)onLogin:(id)sender
{
    [[UserManager sharedManager] loginWithEmail:self.email.text password:self.password.text completion:^(NSError *error) {
        if(error != nil)
        {
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

@end
