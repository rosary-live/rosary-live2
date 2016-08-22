//
//  ListenerCell.h
//  LiveRosary
//
//  Created by richardtaylor on 3/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListenerCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView* avatar;
@property (nonatomic, weak) IBOutlet UILabel* name;
@property (nonatomic, weak) IBOutlet UIImageView* flag;
@property (nonatomic, weak) IBOutlet UILabel* intention;

@end
