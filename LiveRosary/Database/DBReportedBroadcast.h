//
//  DBReportedBroadcast.h
//  LiveRosary
//
//  Created by Richard Taylor on 4/13/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "DBBase.h"
#import "BroadcastModel.h"

@interface DBReportedBroadcast : DBBase

@property (nonatomic, strong, readonly) NSArray<BroadcastModel*>* broadcasts;

+ (instancetype)sharedInstance;

- (void)updateBroadcastsWithCompletion:(void (^)(NSArray<BroadcastModel*>* broadcasts, NSError* error))completion;

@end
