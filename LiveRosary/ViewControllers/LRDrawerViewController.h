//
//  LRDrawerViewController.h
//  LiveRosary
//
//  Created by richardtaylor on 1/11/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LRDrawerViewController : UIViewController

@property (nonatomic, strong) UINavigationController* listenMainViewController;
@property (nonatomic, strong) UINavigationController* broadcastMainViewController;
@property (nonatomic, strong) UINavigationController* adminMainViewController;
@property (nonatomic, strong) UINavigationController* userProfileMainMainViewController;

- (void)showPasswordReset;

@end
