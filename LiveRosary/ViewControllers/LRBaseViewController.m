//
//  LRBaseViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/12/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRBaseViewController.h"
#import "MMDrawerBarButtonItem.h"

@interface LRBaseViewController ()

@property (nonatomic) 

@end

@implementation LRBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[AnalyticsManager sharedManager] screen:[self screenName]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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

- (void)addDrawerButton
{
    MMDrawerBarButtonItem* button = [[MMDrawerBarButtonItem alloc] initWithTarget:[[UIApplication sharedApplication] delegate] action:@selector(onDrawerButton:)];
    [self.navigationItem setLeftBarButtonItem:button];
}

- (NSString*)screenName
{
    NSAssert(NO, @"Must override screenName!");
    return nil;
}

@end
