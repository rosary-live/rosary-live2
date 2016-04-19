//
//  LRListenViewController.h
//  LiveRosary
//
//  Created by richardtaylor on 1/30/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRBaseViewController.h"
#import "BroadcastModel.h"
#import "ReportedBroadcastModel.h"

@interface LRListenViewController : LRBaseViewController

@property (nonatomic, strong) BroadcastModel* broadcast;
@property (nonatomic, strong) ReportedBroadcastModel* reportedBroadcast;
@property (nonatomic) BOOL playFromStart;

@end
