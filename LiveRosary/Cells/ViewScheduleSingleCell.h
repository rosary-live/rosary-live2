//
//  ScheduleCellTableViewCell.h
//  LiveRosary
//
//  Created by richardtaylor on 3/19/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewScheduleSingleCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView* avatarImage;
@property (nonatomic, weak) IBOutlet UILabel* name;
@property (nonatomic, weak) IBOutlet UILabel* location;
@property (nonatomic, weak) IBOutlet UILabel* language;
@property (nonatomic, weak) IBOutlet UILabel* schedule;
@property (nonatomic, weak) IBOutlet UIImageView* alarm;
@property (nonatomic, weak) IBOutlet UIImageView* rosary;
@property (nonatomic, weak) IBOutlet UIImageView* flag;

@end
