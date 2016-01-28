//
//  NSString+Utilities.h
//  LiveRosary
//
//  Created by richardtaylor on 1/21/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Utilities)

+ (NSString*)UUID;
+ (NSString*)filenameForBroadcastId:(NSString*)bid andSequence:(NSInteger)sequence;

@end
