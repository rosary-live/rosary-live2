//
//  NSNumber+Utilities.m
//  LiveRosary
//
//  Created by richardtaylor on 1/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "NSNumber+Utilities.h"

@implementation NSNumber (Utilities)

- (NSDate*)dateForNumber
{
    return [NSDate dateWithTimeIntervalSince1970:self.integerValue];
}

@end
