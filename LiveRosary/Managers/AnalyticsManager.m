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
    id<AWSMobileAnalyticsEventClient> eventClient = self.analytics.eventClient;
    id<AWSMobileAnalyticsEvent> event = [eventClient createEventWithEventType:@"Screen"];
    [event addAttribute:screenName forKey:@"ScreenName"];
    [eventClient recordEvent:event];
}

- (void)event:(NSString*)eventName info:(NSDictionary*)info
{
    id<AWSMobileAnalyticsEventClient> eventClient = self.analytics.eventClient;
    id<AWSMobileAnalyticsEvent> event = [eventClient createEventWithEventType:eventName];
    
    if(info != nil)
    {
        for(NSString* key in info.allKeys)
        {
            id value = [info valueForKey:key];
            if([value isKindOfClass:[NSString class]])
            {
                [event addAttribute:value forKey:key];
            }
            else if([value isKindOfClass:[NSNumber class]])
            {
                [event addMetric:value forKey:key];
            }
        }
    }
    
    [eventClient recordEvent:event];
}

- (void)error:(NSError*)error name:(NSString*)name
{
    id<AWSMobileAnalyticsEventClient> eventClient = self.analytics.eventClient;
    id<AWSMobileAnalyticsEvent> event = [eventClient createEventWithEventType:@"Error"];
    [event addAttribute:name forKey:@"Name"];
    [event addAttribute:error.domain forKey:@"Domain"];
    [event addAttribute:[NSString stringWithFormat:@"%d", (int)error.code] forKey:@"Code"];
    [event addAttribute:error.description forKey:@"Description"];
    [eventClient recordEvent:event];
}

- (void)logRequest:(NSURLRequest*)request response:(NSHTTPURLResponse*)response duration:(CFTimeInterval)duration successful:(BOOL)successful message:(NSString*)message error:(NSString*)error
{
    id<AWSMobileAnalyticsEventClient> eventClient = self.analytics.eventClient;
    id<AWSMobileAnalyticsEvent> event = [eventClient createEventWithEventType:@"Request"];
    [event addAttribute:request.URL.absoluteString forKey:@"URL"];
    [event addMetric:[NSNumber numberWithDouble:duration] forKey:@"Duration"];
    [event addMetric:[NSNumber numberWithInteger:response.statusCode] forKey:@"StatusCode"];
    [event addAttribute:successful ? @"YES" : @"NO" forKey:@"Successful"];
    
    if(message != nil)
    {
        [event addAttribute:message forKey:@"Message"];
    }
    
    if(error != nil)
    {
        [event addAttribute:error.description forKey:@"Error"];
    }
    
    [eventClient recordEvent:event];
}

- (void)flushEvents
{
    id<AWSMobileAnalyticsEventClient> eventClient = self.analytics.eventClient;
    [eventClient submitEvents];
}

@end
