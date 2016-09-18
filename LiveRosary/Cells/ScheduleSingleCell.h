//
//  ScheduleCellTableViewCell.h
//  LiveRosary
//
//  Created by richardtaylor on 3/19/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScheduleSingleCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel* schedule;
@property (nonatomic, weak) IBOutlet UIButton* alarm;
@property (nonatomic, weak) IBOutlet UIButton* remove;

@end
