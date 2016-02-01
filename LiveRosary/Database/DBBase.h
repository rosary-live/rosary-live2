//
//  DBBase.h
//  LiveRosary
//
//  Created by richardtaylor on 1/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSDynamoDB/AWSDynamoDB.h>

@interface DBBase : NSObject

@property (nonatomic, strong) AWSDynamoDBObjectMapper* dynamoDBObjectMapper;

@end
