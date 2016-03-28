//
//  SlideShow.h
//  LiveRosary
//
//  Created by Richard Taylor on 3/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SlideShow : UIView

@property (nonatomic) NSInteger changeInterval;

- (void)start;
- (void)stop;

@end
