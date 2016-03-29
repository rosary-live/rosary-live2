//
//  LRReportBroadcastViewController.m
//  LiveRosary
//
//  Created by Richard Taylor on 3/29/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRReportBroadcastViewController.h"

@interface LRReportBroadcastViewController ()

@property (nonatomic, weak) IBOutlet UIImageView* avatar;
@property (nonatomic, weak) IBOutlet UILabel* name;
@property (nonatomic, weak) IBOutlet UILabel* language;
@property (nonatomic, weak) IBOutlet UILabel* date;
@property (nonatomic, weak) IBOutlet UILabel* location;
@property (nonatomic, weak) IBOutlet UIButton* report;
@property (nonatomic, weak) IBOutlet UILabel* whyLabel;
@property (nonatomic, weak) IBOutlet UITextView* why;

@end

@implementation LRReportBroadcastViewController

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

@end
