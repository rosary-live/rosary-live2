//
//  LRBaseViewController.h
//  LiveRosary
//
//  Created by richardtaylor on 1/12/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DrawerButtonDelegate<NSObject>

- (IBAction)onDrawerButton:(id)sender;

@end

@interface LRBaseViewController : UIViewController

- (void)addDrawerButton;

@end
