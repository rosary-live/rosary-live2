//
//  LRListenMainViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/11/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRListenMainViewController.h"

@interface LRListenMainViewController ()

@end

@implementation LRListenMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem* menuButton = [[UIBarButtonItem alloc] initWithTitle:@"Menu" style:UIBarButtonItemStylePlain target:[[UIApplication sharedApplication] delegate] action:@selector(onMenu:)];
    [self.navigationItem setLeftBarButtonItem:menuButton];
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

@end
