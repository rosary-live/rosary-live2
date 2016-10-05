//
//  MapPinView.h
//  LiveRosary
//
//  Created by Richard Taylor on 10/4/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MapPinView : UIView

@property (nonatomic, weak) IBOutlet UIImageView* avatarImage;
@property (nonatomic, weak) IBOutlet UILabel* name;
@property (nonatomic, weak) IBOutlet UILabel* location;
@property (nonatomic, weak) IBOutlet UILabel* datetime;
@property (nonatomic, weak) IBOutlet UILabel* language;
@property (nonatomic, weak) IBOutlet UIImageView* flag;
@property (nonatomic, weak) IBOutlet UIImageView* alarm;
@property (nonatomic, weak) IBOutlet UIImageView* rosary;

@end
