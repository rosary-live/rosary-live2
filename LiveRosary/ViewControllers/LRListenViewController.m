//
//  LRListenViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/30/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRListenViewController.h"
#import "BroadcastManager.h"
#import "DBBroadcast.h"
#import "NSNumber+Utilities.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "SlideShow.h"
#import "ConfigModel.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface LRListenViewController () <BroadcastManagerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView* avatar;
@property (nonatomic, weak) IBOutlet UILabel* name;
@property (nonatomic, weak) IBOutlet UILabel* language;
@property (nonatomic, weak) IBOutlet UILabel* date;
@property (nonatomic, weak) IBOutlet UILabel* location;
@property (nonatomic, weak) IBOutlet UILabel* status;
@property (nonatomic, weak) IBOutlet SlideShow* slideShow;
@property (nonatomic, weak) IBOutlet UIButton* resumeSlideShow;

@property (nonnull, strong) MBProgressHUD *hud;

@end

@implementation LRListenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = @"Stop";
    
    [BroadcastManager sharedManager].delegate = self;
    
    self.name.text = self.broadcast.name;
    self.language.text = self.broadcast.language;
    self.location.text = [NSString stringWithFormat:@"%@, %@ %@", self.broadcast.city, self.broadcast.state, self.broadcast.country];
    self.date.text = [NSDateFormatter localizedStringFromDate:[self.broadcast.updated dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    self.status.text = @"Loading";
    
    NSString* urlString = [NSString stringWithFormat:@"https://s3.amazonaws.com/liverosaryavatars/%@", [self.broadcast.user stringByReplacingOccurrencesOfString:@"@" withString:@"-"]];
    [self.avatar sd_setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:[UIImage imageNamed:@"AvatarImage"] options:0];

    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = @"Loading";

    [[DBBroadcast sharedInstance] getBroadcastById:self.broadcast.bid completion:^(BroadcastModel *broadcast, NSError *error) {
        DDLogDebug(@"updated broadcast %@", broadcast);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.hud hide:YES];
            
            if(broadcast.isLive || self.playFromStart)
            {
                self.status.text = @"Playing";
                [[BroadcastManager sharedManager] startPlayingBroadcastWithId:self.broadcast.bid atSequence:self.playFromStart ? 1 : broadcast.sequence.integerValue completion:^(BOOL insufficientBandwidth) {
                    if(insufficientBandwidth)
                    {
                        [UIAlertView bk_showAlertViewWithTitle:nil message:@"Insufficient bandwidth to listen." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                            
                            [self.navigationController popViewControllerAnimated:YES];
                        }];
                    }
                    
                }];
            }
            else
            {
                self.status.text = @"Broadcast Has Ended";
            }
        });
    }];
    
    self.slideShow.changeInterval = [ConfigModel sharedInstance].slideShowChangeInterval;
    self.resumeSlideShow.hidden = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([ConfigModel sharedInstance].slideShowStartDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startSlideShow];
        self.resumeSlideShow.hidden = NO;
    });
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[BroadcastManager sharedManager] stopPlaying];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onResumeSlideShow:(id)sender
{
    [self startSlideShow];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - BroadcastManagerDelegate

- (void)broadcastHasEnded
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.status.text = @"Broadcast Has Ended";
        [self stopSlideShow];
        self.resumeSlideShow.hidden = YES;
    });
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if(!self.slideShow.hidden)
    {
        [self stopSlideShow];
    }
}

- (void)startSlideShow
{
    self.slideShow.alpha = 0.0;
    self.slideShow.hidden = NO;
    [self.slideShow start];
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    [UIView animateWithDuration:0.5 animations:^{
        self.slideShow.alpha = 1.0;
    }];
}

- (void)stopSlideShow
{
    [self.slideShow stop];
    [UIView animateWithDuration:1.0 animations:^{
        self.slideShow.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.slideShow.hidden = YES;
        [[self navigationController] setNavigationBarHidden:NO animated:YES];
    }];
}

@end
