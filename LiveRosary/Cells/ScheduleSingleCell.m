//
//  ScheduleCellTableViewCell.m
//  LiveRosary
//
//  Created by richardtaylor on 3/19/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "ScheduleSingleCell.h"

@implementation ScheduleSingleCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    [self.alarm removeTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
    [self.remove removeTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
}

@end
