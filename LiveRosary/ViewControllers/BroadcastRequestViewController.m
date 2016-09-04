//
//  BroadcastRequestViewController.m
//  LiveRosary
//
//  Created by Richard Taylor on 8/29/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "BroadcastRequestViewController.h"
#import "DBUser.h"

@interface BroadcastRequestViewController ()

@end

@implementation BroadcastRequestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[DBUser sharedInstance] getUsersWithBroadcastRequest:nil completion:^(NSArray<UserModel *> *users, NSDictionary *moreKey, NSError *error) {
        NSLog(@"%@ %@", error, users);
    }];
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
    return @"Broadcast Request";
}
@end
