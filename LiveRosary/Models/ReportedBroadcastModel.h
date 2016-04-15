//
//  ReportedBroadcast.h
//  LiveRosary
//
//  Created by Richard Taylor on 4/14/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "BaseModel.h"
#import <MapKit/MapKit.h>

@interface ReportedBroadcastModel : BaseModel <MKAnnotation>

@property (nonatomic, strong) NSNumber* version;
@property (nonatomic, strong) NSString* bid;
@property (nonatomic, strong) NSNumber* sequence;
@property (nonatomic, strong) NSString* reason;
@property (nonatomic, strong) NSString* link;

@property (nonatomic, strong) NSNumber* created;

@property (nonatomic, strong) NSNumber* b_created;
@property (nonatomic, strong) NSNumber* b_updated;

@property (nonatomic, strong) NSString* b_email;
@property (nonatomic, strong) NSString* b_name;
@property (nonatomic, strong) NSString* b_language;
@property (nonatomic, strong) NSString* b_city;
@property (nonatomic, strong) NSString* b_state;
@property (nonatomic, strong) NSString* b_country;
@property (nonatomic, strong) NSNumber* b_lat;
@property (nonatomic, strong) NSNumber* b_lon;

@property (nonatomic, strong) NSString* r_email;
@property (nonatomic, strong) NSString* r_name;
@property (nonatomic, strong) NSString* r_language;
@property (nonatomic, strong) NSString* r_city;
@property (nonatomic, strong) NSString* r_state;
@property (nonatomic, strong) NSString* r_country;
@property (nonatomic, strong) NSNumber* r_lat;
@property (nonatomic, strong) NSNumber* r_lon;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy, nullable) NSString* title;
@property (nonatomic, readonly, copy, nullable) NSString* subtitle;

@end
