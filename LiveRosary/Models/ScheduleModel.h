//
//  ScheduleModel.h
//  LiveRosary
//
//  Created by richardtaylor on 3/16/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "BaseModel.h"
#import <MapKit/MapKit.h>

@interface ScheduleModel : BaseModel <MKAnnotation>

@property (nonatomic, strong) NSNumber* version;
@property (nonatomic, strong) NSString* sid;

@property (nonatomic, strong) NSNumber* created;
@property (nonatomic, strong) NSNumber* updated;

@property (nonatomic, strong) NSString* user;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* language;
@property (nonatomic, strong) NSString* city;
@property (nonatomic, strong) NSString* state;
@property (nonatomic, strong) NSString* country;
@property (nonatomic, strong) NSNumber* lat;
@property (nonatomic, strong) NSNumber* lon;

@property (nonatomic, strong) NSString* type;

// Single
@property (nonatomic, strong) NSNumber* start;

// Recurring
@property (nonatomic, strong) NSNumber* from;
@property (nonatomic, strong) NSNumber* to;
@property (nonatomic, strong) NSNumber* at;
@property (nonatomic, strong) NSNumber* days;

@property (nonatomic, readonly) BOOL isSingle;
@property (nonatomic, readonly) BOOL isRecurring;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy, nullable) NSString* title;
@property (nonatomic, readonly, copy, nullable) NSString* subtitle;

@end
