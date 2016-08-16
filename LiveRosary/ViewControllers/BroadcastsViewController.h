//
//  BroadcastsViewController.h
//  LiveRosary
//
//  Created by richardtaylor on 3/5/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BroadcastModel.h"
#import "ScheduleModel.h"
#import "ReportedBroadcastModel.h"

@protocol BroadcastsViewDelegate <NSObject>

@optional
- (void)selectedBroadcast:(BroadcastModel*)model;
- (void)selectedSchedule:(ScheduleModel*)model;
- (void)selectedReportedBroadcast:(ReportedBroadcastModel*)model;

@end

@interface BroadcastsViewController : UIViewController

+ (instancetype)instantiate;

@property (nonatomic, weak) id<BroadcastsViewDelegate> delegate;
@property (nonatomic) BOOL liveOnly;
@property (nonatomic) BOOL showReportedBroadcasts;
@property (nonatomic) BOOL allScheduledBroadcasts;

- (void)update;

@end
