//
//  BroadcastsTableView.h
//  LiveRosary
//
//  Created by richardtaylor on 2/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BroadcastModel.h"

@protocol BroadcastsViewDelegate <NSObject>

- (void)selectedBroadcast:(BroadcastModel*)model;

@end

@interface BroadcastsView : UIView

@property (nonatomic, weak) id<BroadcastsViewDelegate> delegate;
@property (nonatomic) BOOL liveOnly;

- (void)updateBroadcasts;

@end
