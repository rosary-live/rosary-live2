//
//  BroadcastsTableView.h
//  LiveRosary
//
//  Created by richardtaylor on 2/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BroadcastModel.h"

@protocol BroadcastsTableViewActionDelegate <NSObject>

- (void)selectedBroadcast:(BroadcastModel*)model;

@end

@interface BroadcastsTableView : UITableView

@property (nonatomic, weak) id<BroadcastsTableViewActionDelegate> actionDelegate;
@property (nonatomic) BOOL liveOnly;

- (void)updateBroadcasts;

@end
