//
//  AnalyticsManager.m
//  LiveRosary
//
//  Created by Richard Taylor on 3/31/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "AnalyticsManager.h"

@implementation AnalyticsManager

+ (instancetype)sharedManager
{
    static AnalyticsManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if(self != nil)
    {
    }
    return self;
}

@end
