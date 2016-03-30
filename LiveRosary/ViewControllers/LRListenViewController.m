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
#import "BroadcastQueueModel.h"
#import "UserManager.h"
#import "LRReportBroadcastViewController.h"

NSString * const kLastIntentionKey = @"LastIntention";

@interface LRListenViewController () <BroadcastManagerDelegate, UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UIImageView* avatar;
@property (nonatomic, weak) IBOutlet UILabel* name;
@property (nonatomic, weak) IBOutlet UILabel* language;
@property (nonatomic, weak) IBOutlet UILabel* date;
@property (nonatomic, weak) IBOutlet UILabel* location;
@property (nonatomic, weak) IBOutlet UILabel* status;
@property (nonatomic, weak) IBOutlet SlideShow* slideShow;
@property (nonatomic, weak) IBOutlet UIButton* resumeSlideShow;
@property (nonatomic, weak) IBOutlet UILabel* intentionLabel;
@property (nonatomic, weak) IBOutlet UITextView* intention;
@property (nonatomic, weak) IBOutlet UIButton* report;

@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic) BOOL editingIntention;
@property (nonatomic, strong) NSString* lastIntention;

@property (nonatomic) BOOL reporting;


@end

@implementation LRListenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = @"Stop";
    
    if(self.playFromStart)
    {
        self.intentionLabel.hidden = YES;
        self.intention.hidden = YES;
        //self.report.hidden = YES;
    }
    else
    {
        self.lastIntention = [[NSUserDefaults standardUserDefaults] objectForKey:kLastIntentionKey];
        if(self.lastIntention == nil) self.lastIntention = @"";
        
        self.intention.text = self.lastIntention;
    }
    
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
                    else
                    {
                        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

                        if(!self.playFromStart)
                        {
                            NSMutableDictionary* userDict = [[UserManager sharedManager].userDictionary mutableCopy];
                            userDict[@"intention"] = self.intention.text != nil ? self.intention.text : @"";
                            [[BroadcastQueueModel sharedInstance] sendEnterForBroadcastId:self.broadcast.bid withDictionary:userDict];
                        }
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
    
    [self startSlideShowTimer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.reporting = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];

    [[BroadcastManager sharedManager] stopPlaying];
    
    if(!self.playFromStart)
    {
        [[BroadcastQueueModel sharedInstance] sendExitForBroadcastId:self.broadcast.bid withDictionary:[UserManager sharedManager].userDictionary];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startSlideShowTimer
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([ConfigModel sharedInstance].slideShowStartDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(self.editingIntention || self.reporting)
        {
            [self startSlideShowTimer];
        }
        else
        {
            [self startSlideShow];
            self.resumeSlideShow.hidden = NO;
        }
    });
}

- (IBAction)onResumeSlideShow:(id)sender
{
    [self startSlideShow];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    LRReportBroadcastViewController* reportViewController = [segue destinationViewController];
    reportViewController.broadcast = self.broadcast;
    self.reporting = YES;
}

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

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.editingIntention = YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.editingIntention = NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"])
    {
        if(![self.lastIntention isEqualToString:self.intention.text])
        {
            NSMutableDictionary* userDict = [[UserManager sharedManager].userDictionary mutableCopy];
            self.lastIntention = self.intention.text;
            [[NSUserDefaults standardUserDefaults] setObject:self.lastIntention forKey:kLastIntentionKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            userDict[@"intention"] = self.intention.text != nil ? self.intention.text : @"";
            [[BroadcastQueueModel sharedInstance] sendUpdateForBroadcastId:self.broadcast.bid withDictionary:userDict];
        }
        
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

@end
