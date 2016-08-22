//
//  LRAdminTabBarController.m
//  LiveRosary
//
//  Created by richardtaylor on 2/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRAdminMainViewController.h"

@interface LRAdminMainViewController ()

@property (nonatomic, weak) IBOutlet UIView* allBroadcastsView;
@property (nonatomic, weak) IBOutlet UIView* reportedBroadcastsView;
@property (nonatomic, weak) IBOutlet UIView* manageUsersView;

@end

@implementation LRAdminMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self addDrawerButton];
    
    self.view.backgroundColor = [UIColor colorFromHexString:@"#E7D8B9"];
    
    self.allBroadcastsView.layer.cornerRadius = 4;
    self.reportedBroadcastsView.layer.cornerRadius = 4;
    self.manageUsersView.layer.cornerRadius = 4;
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

- (NSString*)screenName
{
    return @"Admin Main";
}

@end
