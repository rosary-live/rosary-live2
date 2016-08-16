//
//  DBBroadcast.h
//  LiveRosary
//
//  Created by richardtaylor on 1/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "DBBase.h"
#import "BroadcastModel.h"

@interface DBBroadcast : DBBase

@property (nonatomic, strong, readonly) NSArray<BroadcastModel*>* broadcasts;

+ (instancetype)sharedInstance;

- (void)updateBroadcastsWithCompletion:(void (^)(NSArray<BroadcastModel*>* broadcasts, NSError* error))completion;
- (void)getBroadcastById:(NSString*)bid completion:(void (^)(BroadcastModel* broadcast, NSError* error))completion;

@end
