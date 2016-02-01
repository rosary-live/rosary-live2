//
//  BroadcastModel.h
//  LiveRosary
//
//  Created by richardtaylor on 1/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "BaseModel.h"

@interface BroadcastModel : BaseModel

@property (nonatomic, strong) NSNumber* version;
@property (nonatomic, strong) NSString* bid;
@property (nonatomic, strong) NSNumber* sequence;

@property (nonatomic, strong) NSNumber* created;
@property (nonatomic, strong) NSNumber* updated;

@property (nonatomic, strong) NSNumber* live;

@property (nonatomic, strong) NSString* user;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* language;
@property (nonatomic, strong) NSString* city;
@property (nonatomic, strong) NSString* state;
@property (nonatomic, strong) NSString* country;
@property (nonatomic, strong) NSNumber* lat;
@property (nonatomic, strong) NSNumber* lon;

@property (nonatomic, strong) NSString* compression;
@property (nonatomic, strong) NSNumber* bits;
@property (nonatomic, strong) NSNumber* channels;
@property (nonatomic, strong) NSNumber* rate;
@property (nonatomic, strong) NSNumber* segment_duration;

@end
