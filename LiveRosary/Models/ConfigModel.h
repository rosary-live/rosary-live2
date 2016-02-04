//
//  ConfigModel.h
//  LiveRosary
//
//  Created by richardtaylor on 2/1/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConfigModel : NSObject

@property (nonatomic, readonly, getter=isLoaded) BOOL loaded;

@property (nonatomic, readonly) NSInteger sampleRate;
@property (nonatomic, readonly) NSInteger segmentSizeSeconds;
@property (nonatomic, readonly) NSInteger maxBroadcastSeconds;
@property (nonatomic, readonly) NSInteger compressionBitRate;

+ (instancetype)sharedInstance;

- (void)loadConfigWithCompletion:(void (^)(NSError* error))completion;

@end
