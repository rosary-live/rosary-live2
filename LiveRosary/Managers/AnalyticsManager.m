//
//  AnalyticsManager.m
//  LiveRosary
//
//  Created by Richard Taylor on 3/31/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "AnalyticsManager.h"
#import <AWSMobileAnalytics/AWSMobileAnalytics.h>

@interface AnalyticsManager ()

@property (nonatomic, strong) AWSMobileAnalytics* analytics;

@end

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
        self.analytics = [AWSMobileAnalytics mobileAnalyticsForAppId: @"21d2dc7286724ff8a12d151757ae190e" identityPoolId: @"us-east-1:e071f60e-332c-4883-a4f0-f8bc27c46173"];
    }
    return self;
}

- (void)screen:(NSString*)screenName
{
}

- (void)event:(NSString*)event info:(NSDictionary*)info
{
}

- (void)error:(NSError*)error
{
}

@end
