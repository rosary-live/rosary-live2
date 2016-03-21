//
//  ScheduleRecurringCell.h
//  LiveRosary
//
//  Created by richardtaylor on 3/19/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewScheduleRecurringCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView* avatarImage;
@property (nonatomic, weak) IBOutlet UILabel* name;
@property (nonatomic, weak) IBOutlet UILabel* location;
@property (nonatomic, weak) IBOutlet UILabel* language;
@property (nonatomic, weak) IBOutlet UILabel* fromDate;
@property (nonatomic, weak) IBOutlet UILabel* toDate;
@property (nonatomic, weak) IBOutlet UILabel* atTime;
@property (nonatomic, weak) IBOutlet UILabel* daysOfWeek;

@end
