//
//  NSDictionary+Utilities.m
//  LiveRosary
//
//  Created by richardtaylor on 1/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "NSDictionary+Utilities.h"

@implementation NSDictionary (Utilities)

- (NSDictionary *)fs_dictionaryByAddingDictionary:(NSDictionary*)otherDictionary
{
    NSMutableDictionary* md = [self mutableCopy];
    [md addEntriesFromDictionary:otherDictionary];
    return md;
}

@end
