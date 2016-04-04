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
- (void)event:(NSString*)eventName info:(NSDictionary*)info;
- (void)error:(NSError*)error name:(NSString*)name;
- (void)logRequest:(NSURLRequest*)request response:(NSHTTPURLResponse*)response duration:(CFTimeInterval)duration successful:(BOOL)successful message:(NSString*)message error:(NSString*)error;

- (void)flushEvents;

@end
