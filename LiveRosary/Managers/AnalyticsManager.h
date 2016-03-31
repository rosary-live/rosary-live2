//
//  AnalyticsManager.h
//  LiveRosary
//
//  Created by Richard Taylor on 3/31/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnalyticsManager : NSObject

+ (instancetype)sharedManager;

- (void)screen:(NSString*)screenName;
- (void)event:(NSString*)event info:(NSDictionary*)info;
- (void)error:(NSError*)error;

@end
