//
//  NSString+Utilities.m
//  LiveRosary
//
//  Created by richardtaylor on 1/21/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "NSString+Utilities.h"

@implementation NSString (Utilities)

+ (NSString*)UUID
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    return (__bridge_transfer NSString *)uuidStringRef;
}

+ (NSString*)filenameForBroadcastId:(NSString*)bid andSequence:(NSInteger)sequence
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat: @"%@-%06d", bid, (int)sequence]];
}

- (BOOL)validEmailAddress
{
    NSString* emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate* emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

@end
