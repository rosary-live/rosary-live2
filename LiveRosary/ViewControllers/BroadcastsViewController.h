//
//  BroadcastsViewController.h
//  LiveRosary
//
//  Created by richardtaylor on 3/5/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BroadcastModel.h"

@protocol BroadcastsViewDelegate <NSObject>

- (void)selectedBroadcast:(BroadcastModel*)model;

@end

@interface BroadcastsViewController : UIViewController

+ (instancetype)instantiate;

@property (nonatomic, weak) id<BroadcastsViewDelegate> delegate;
@property (nonatomic) BOOL liveOnly;

- (void)update;

@end
