//
//  UIImageView+Utilities.m
//  LiveRosary
//
//  Created by Richard Taylor on 8/21/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "UIImageView+Utilities.h"

@implementation UIImageView (Utilities)

- (void)addRosaryAnimation {
    self.animationImages = @[
                        [UIImage imageNamed:@"Rosary1"],
                        [UIImage imageNamed:@"Rosary2"],
                        [UIImage imageNamed:@"Rosary3"],
                        [UIImage imageNamed:@"Rosary4"],
                        [UIImage imageNamed:@"Rosary5"],
                        [UIImage imageNamed:@"Rosary6"],
                        [UIImage imageNamed:@"Rosary7"],
                        [UIImage imageNamed:@"Rosary8"],
                        [UIImage imageNamed:@"Rosary9"]
                        ];
    
    self.animationDuration = 1.0;
}

@end
