//
//  LRDrawerViewController.h
//  LiveRosary
//
//  Created by richardtaylor on 1/11/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRBaseViewController.h"

@interface LRDrawerViewController : LRBaseViewController

@property (nonatomic, strong) UINavigationController* listenMainViewController;
@property (nonatomic, strong) UINavigationController* broadcastMainViewController;
@property (nonatomic, strong) UINavigationController* broadcastRequestViewController;
@property (nonatomic, strong) UINavigationController* adminMainViewController;
@property (nonatomic, strong) UINavigationController* userProfileMainMainViewController;

- (void)showPasswordReset;

@end
