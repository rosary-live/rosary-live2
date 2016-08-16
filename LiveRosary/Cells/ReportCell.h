//
//  ReportCell.h
//  LiveRosary
//
//  Created by Richard Taylor on 4/15/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReportCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView* avatar;
@property (nonatomic, weak) IBOutlet UILabel* name;
@property (nonatomic, weak) IBOutlet UILabel* language;
@property (nonatomic, weak) IBOutlet UILabel* date;
@property (nonatomic, weak) IBOutlet UILabel* reporter;
@property (nonatomic, weak) IBOutlet UILabel* reason;

@end
