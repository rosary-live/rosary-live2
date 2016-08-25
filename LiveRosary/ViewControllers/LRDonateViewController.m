//
//  LRDonateViewController.m
//  LiveRosary
//
//  Created by Richard Taylor on 8/22/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRDonateViewController.h"
#import "ConfigModel.h"

@interface LRDonateViewController ()

@property (nonatomic, weak) IBOutlet UIWebView* webView;
@end

@implementation LRDonateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL* url = [NSURL URLWithString:[ConfigModel sharedInstance].donateURL];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

@end
