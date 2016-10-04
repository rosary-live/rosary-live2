//
//  LRBaseViewController.h
//  LiveRosary
//
//  Created by richardtaylor on 1/12/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LOGIN_NOTIFICATION_NAME @"LOGIN_NOTIFICATION"
#define LOGOUT_NOTIFICATION_NAME @"LOGOUT_NOTIFICATION"

@protocol DrawerButtonDelegate <NSObject>

- (IBAction)onDrawerButton:(id)sender;

@end

@interface LRBaseViewController : UIViewController

- (void)addDrawerButton;
- (NSString*)screenName;
- (BOOL)hideNavBar;
- (void)showProgress:(NSString*)message;
- (void)hideProgress;
- (void)updateScreen;

@end
