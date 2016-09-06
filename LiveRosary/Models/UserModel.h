//
//  UserModel.h
//  LiveRosary
//
//  Created by richardtaylor on 1/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "BaseModel.h"

typedef NS_ENUM(NSUInteger, UserLevel) {
    UserLevelAdmin,
    UserLevelBroadcaster,
    UserLevelListener,
    UserLevelBanned
};

@interface UserModel : BaseModel

@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* firstName;
@property (nonatomic, strong) NSString* lastName;
@property (nonatomic, strong) NSString* language;
@property (nonatomic, strong) NSNumber* latitude;
@property (nonatomic, strong) NSNumber* longitude;
@property (nonatomic, strong) NSString* city;
@property (nonatomic, strong) NSString* state;
@property (nonatomic, strong) NSString* country;
@property (nonatomic, strong) NSNumber* avatar;
@property (nonatomic, strong) NSString* level;
@property (nonatomic, readonly) UserLevel userLevel;
@property (nonatomic, strong) NSNumber* breq;
@property (nonatomic, strong) NSString* reqtext;

- (id)initWithDict:(NSDictionary*)dict;


@end
