//
//  DBReportedBroadcast.h
//  LiveRosary
//
//  Created by Richard Taylor on 4/13/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "DBBase.h"
#import "ReportedBroadcastModel.h"

@interface DBReportedBroadcast : DBBase

@property (nonatomic, strong, readonly) NSArray<ReportedBroadcastModel*>* broadcasts;

+ (instancetype)sharedInstance;

- (void)updateReportedBroadcastsWithCompletion:(void (^)(NSArray<ReportedBroadcastModel*>* broadcasts, NSError* error))completion;

@end
