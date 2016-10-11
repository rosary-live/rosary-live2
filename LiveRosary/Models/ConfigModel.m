//
//  ConfigModel.m
//  LiveRosary
//
//  Created by richardtaylor on 2/1/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "ConfigModel.h"
#import <AFNetworking/AFNetworking.h>

NSString * const UserDefaultsKeyConfigSettings = @"ConfigSettings";

@implementation ConfigModel

+ (instancetype)sharedInstance
{
    static ConfigModel* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super self];
    if(self)
    {
        NSDictionary* configDict = [[NSUserDefaults standardUserDefaults] objectForKey:UserDefaultsKeyConfigSettings];
        if(configDict != nil)
        {
            [self loadSettingsFromDictionary:configDict];
        }
        else
        {
            // Set defaults
            _maxBroadcastSeconds = 1500;
            _sampleRate = 11025;
            _segmentSizeSeconds = 5.0;
            _slideShowStartDelay = 5;
            _slideShowChangeInterval = 10;
            _donateURL = @"http://rosary.live/donate/";
        }
    }
    return self;
}

- (void)loadConfigWithCompletion:(void (^)(NSError* error))completion
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSMutableURLRequest* request = [[AFJSONRequestSerializer serializer] requestWithMethod:@"GET" URLString:@"https://s3.amazonaws.com/liverosaryweb/config.json" parameters:nil error:nil];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
            safeBlock(completion, error);
        } else {
            NSLog(@"%@ %@", response, responseObject);
            NSDictionary* configDict = responseObject;
            
            [self loadSettingsFromDictionary:configDict];
            
            // Store settings
            [[NSUserDefaults standardUserDefaults] setObject:configDict forKey:UserDefaultsKeyConfigSettings];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            safeBlock(completion, nil);
        }
    }];
    
    [dataTask resume];
}

- (void)loadSettingsFromDictionary:(NSDictionary*)configDict
{
    _maxBroadcastSeconds = ((NSNumber*)configDict[@"maxBroadcastSeconds"]).integerValue;
    _sampleRate = ((NSNumber*)configDict[@"sampleRate"]).integerValue;
    _segmentSizeSeconds = ((NSNumber*)configDict[@"segmentSizeSeconds"]).doubleValue;
    _slideShowStartDelay = ((NSNumber*)configDict[@"slideShowStartDelay"]).integerValue;
    _slideShowChangeInterval = ((NSNumber*)configDict[@"slideShowChangeInterval"]).integerValue;
    _slideImageURLs = configDict[@"slideImageURLs"];
    _donateURL = configDict[@"donateURL"];
}

@end
