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
#import "LiveRosaryService.h"
#import "DBUser.h"

NSString * const kLastIntentionKey = @"LastIntention";

@interface LRListenViewController () <BroadcastManagerDelegate, UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UIImageView* avatar;
@property (nonatomic, weak) IBOutlet UILabel* name;
@property (nonatomic, weak) IBOutlet UILabel* language;
@property (nonatomic, weak) IBOutlet UILabel* date;
@property (nonatomic, weak) IBOutlet UILabel* location;
@property (nonatomic, weak) IBOutlet UILabel* status;
@property (nonatomic, weak) IBOutlet SlideShow* slideShow;
@property (nonatomic, weak) IBOutlet UITableView* tableView;

@property (nonatomic, weak) IBOutlet UIButton* resumeSlideShow;
@property (nonatomic, weak) IBOutlet UILabel* intentionLabel;
@property (nonatomic, weak) IBOutlet UITextView* intention;
@property (nonatomic, weak) IBOutlet UIButton* report;

@property (nonatomic, weak) IBOutlet UIButton* revokeBroadcastPriv;
@property (nonatomic, weak) IBOutlet UIButton* banUser;

@property (nonatomic, strong) NSTimer* playTimer;

@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic) BOOL editingIntention;
@property (nonatomic, strong) NSString* lastIntention;

@property (nonatomic) BOOL reporting;

@property (nonatomic) CFTimeInterval startTime;

@property (nonatomic) BOOL isReport;

@property (nonatomic, strong) NSMutableArray* listeners;

@end

@implementation LRListenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = @"Stop";
    
    self.isReport = self.reportedBroadcast != nil;
    self.listeners = [NSMutableArray new];
    
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
    
    if(self.isReport)
    {
        self.intentionLabel.hidden = YES;
        self.intention.hidden = YES;
        self.report.hidden = YES;
        self.revokeBroadcastPriv.hidden = NO;
        self.banUser.hidden = NO;
    }
    else
    {
        self.intentionLabel.hidden = NO;
        self.intention.hidden = NO;
        self.report.hidden = NO;
        self.revokeBroadcastPriv.hidden = YES;
        self.banUser.hidden = YES;
    }
    
    [BroadcastManager sharedManager].delegate = self;
    
    self.name.text = self.isReport ? self.reportedBroadcast.b_name : self.broadcast.name;
    self.language.text = self.isReport ? self.reportedBroadcast.b_language : self.broadcast.language;
    self.location.text = [NSString stringWithFormat:@"%@, %@ %@",
                          self.isReport ? self.reportedBroadcast.b_city : self.broadcast.city,
                          self.isReport ? self.reportedBroadcast.b_state : self.broadcast.state,
                          self.isReport ? self.reportedBroadcast.b_country : self.broadcast.country];
    self.date.text = [NSDateFormatter localizedStringFromDate:[self.isReport ? self.reportedBroadcast.b_updated : self.broadcast.updated dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    self.status.text = @"Loading";
    
    NSString* urlString = [NSString stringWithFormat:@"https://s3.amazonaws.com/liverosaryavatars/%@", [self.broadcast.user stringByReplacingOccurrencesOfString:@"@" withString:@"-"]];
    [self.avatar sd_setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:[UIImage imageNamed:@"AvatarImage"] options:0];

    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = @"Loading";

    [[DBBroadcast sharedInstance] getBroadcastById:self.isReport ? self.reportedBroadcast.bid : self.broadcast.bid completion:^(BroadcastModel *broadcast, NSError *error) {
        DDLogDebug(@"updated broadcast %@", broadcast);
        
        if(error == nil)
        {
            if(self.isReport)
            {
                self.broadcast = broadcast;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.hud hide:YES];
                
                if(broadcast.isLive || self.playFromStart)
                {
                    self.status.text = @"Playing";
                    [[BroadcastManager sharedManager] startPlayingBroadcastWithId:self.broadcast.bid atSequence:self.playFromStart ? 1 : broadcast.sequence.integerValue completion:^(BOOL insufficientBandwidth) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(insufficientBandwidth)
                            {
                                [UIAlertView bk_showAlertViewWithTitle:nil message:@"Insufficient bandwidth to listen." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                    
                                    [self.navigationController popViewControllerAnimated:YES];
                                }];
                            }
                            else
                            {
                                self.startTime = CACurrentMediaTime();
                                
                                self.playTimer = [NSTimer bk_scheduledTimerWithTimeInterval:0.95 block:^(NSTimer *timer) {
                                    int baseTime = self.playFromStart ? 0 : (broadcast.sequence.integerValue - 1) * [ConfigModel sharedInstance].segmentSizeSeconds;
                                    int playTime = baseTime + (int)(CACurrentMediaTime() - self.startTime);
                                    int minutes = playTime / 60;
                                    int seconds = playTime % 60;
                                    self.status.text = [NSString stringWithFormat:@"Playing %d:%02d", minutes, seconds];
                                } repeats:YES];
                                
                                [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

                                if(self.playFromStart)
                                {
                                    [[AnalyticsManager sharedManager] event:@"PlayFromStart" info:@{@"bid": self.broadcast.bid}];
                                }
                                else if(self.isReport)
                                {
                                    [[AnalyticsManager sharedManager] event:@"PlayReport" info:@{@"bid": self.reportedBroadcast.bid}];
                                }
                                else
                                {
                                    [[BroadcastQueueModel sharedInstance] startReceivingForBroadcastId:self.broadcast.bid asBroadcaster:NO event:^(NSArray *events) {
                                        NSLog(@"events %@", events);
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            for(NSDictionary* event in events)
                                            {
                                                NSString* type = event[@"type"];
                                                if([type isEqualToString:@"enter"])
                                                {
                                                    NSDictionary* listener = event[@"event"];
                                                    if([self listenerForEmail:listener[@"email"]] == nil)
                                                    {
                                                        [self.listeners addObject:listener];
                                                        
                                                    }
                                                }
                                                else if([type isEqualToString:@"exit"])
                                                {
                                                    NSDictionary* listener = event[@"event"];
                                                    NSDictionary* existingListener = [self listenerForEmail:listener[@"email"]];
                                                    if(existingListener != nil)
                                                    {
                                                        [self.listeners removeObject:existingListener];
                                                    }
                                                }
                                                else if([type isEqualToString:@"update"])
                                                {
                                                    NSDictionary* listener = event[@"event"];
                                                    NSDictionary* existingListener = [self listenerForEmail:listener[@"email"]];
                                                    if(existingListener != nil)
                                                    {
                                                        NSUInteger index = [self.listeners indexOfObject:existingListener];
                                                        if(index != NSNotFound)
                                                        {
                                                            [self.listeners replaceObjectAtIndex:index withObject:listener];
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            [self.tableView reloadData];
                                        });
                                    }];
                                    
                                    [[AnalyticsManager sharedManager] event:@"Play" info:@{@"bid": self.broadcast.bid}];
                                    NSMutableDictionary* userDict = [[UserManager sharedManager].userDictionary mutableCopy];
                                    userDict[@"intention"] = self.intention.text != nil ? self.intention.text : @"";
                                    [[BroadcastQueueModel sharedInstance] sendEnterForBroadcastId:self.broadcast.bid withDictionary:userDict];
                                }
                            }
                        });
                        
                    }];
                }
                else
                {
                    self.status.text = @"Broadcast Has Ended";
                }
            });
        }
        else
        {
            [[AnalyticsManager sharedManager] event:@"PlayGetBroadcastError" info:@{@"bid": self.isReport ? self.reportedBroadcast.bid : self.broadcast.bid}];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.hud hide:YES];
                
                [UIAlertView bk_showAlertViewWithTitle:nil message:@"Failed to start broadcast." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    
                    [self.navigationController popViewControllerAnimated:YES];
                }];
            });
        }
    }];
    
    self.slideShow.changeInterval = [ConfigModel sharedInstance].slideShowChangeInterval;
    self.resumeSlideShow.hidden = YES;
    
    if(!self.isReport)
    {
        [self startSlideShowTimer];
    }
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
    
    if([BroadcastManager sharedManager].state == BroadcastStatePlaying)
    {
        [[AnalyticsManager sharedManager] event:@"LeftPlayerScreen" info:@{@"bid": self.broadcast.bid}];
        [[AnalyticsManager sharedManager] event:@"PlayDuration" info:@{@"bid": self.broadcast.bid, @"duration": @(CACurrentMediaTime() - self.startTime), @"over": @(0)}];

        [[BroadcastManager sharedManager] stopPlaying];
    }
    
    if(!self.playFromStart)
    {
        [[BroadcastQueueModel sharedInstance] sendExitForBroadcastId:self.broadcast.bid withDictionary:[UserManager sharedManager].userDictionary];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)screenName
{
    return @"Listen";
}

- (NSDictionary*)listenerForEmail:(NSString*)email
{
    if(email != nil && email.length > 0)
    {
        NSPredicate* byEmail = [NSPredicate predicateWithFormat:@"email == %@", email];
        NSArray* result = [self.listeners filteredArrayUsingPredicate:byEmail];
        if(result != nil && result.count > 0)
        {
            return result[0];
        }
    }
    
    return nil;
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
    [[AnalyticsManager sharedManager] event:@"ResumedSlideShow" info:@{@"bid": self.broadcast.bid}];

    [self startSlideShow];
}

- (IBAction)onRevokeBroadcast:(id)sender
{
    [self updateUser:self.reportedBroadcast.b_email toLevel:@"listener"];
}

- (IBAction)onBanUser:(id)sender
{
    [self updateUser:self.reportedBroadcast.b_email toLevel:@"banned"];
}

- (void)updateUser:(NSString*)email toLevel:(NSString*)level
{
    DDLogDebug(@"User -> %@ %@", email, level);
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = @"Updating User";
    [[LiveRosaryService sharedService] updateUserWithEmail:email toLevel:level adminEmail:[UserManager sharedManager].email adminPassword:[UserManager sharedManager].password completion:^(NSError *error) {
        
        if(error == nil)
        {
            [[DBUser sharedInstance] updateLevelForEmail:email from:@"broadcaster" to:level];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.hud hide:YES];
            [self.navigationController popViewControllerAnimated:YES];
        });
    }];
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
    if([BroadcastManager sharedManager].state == BroadcastStatePlaying)
    {
        [self.playTimer invalidate];
        
        [[AnalyticsManager sharedManager] event:@"PlayEnded" info:@{@"bid": self.broadcast.bid}];
        [[AnalyticsManager sharedManager] event:@"PlayDuration" info:@{@"bid": self.broadcast.bid, @"duration": @(CACurrentMediaTime() - self.startTime), @"over": @(1)}];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.status.text = @"Broadcast Has Ended";
            [self stopSlideShow];
            self.resumeSlideShow.hidden = YES;
        });
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if(!self.slideShow.hidden)
    {
        [[AnalyticsManager sharedManager] event:@"StoppedSlideShow" info:@{@"bid": self.broadcast.bid}];

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
            [[AnalyticsManager sharedManager] event:@"CangedIntention" info:@{@"bid": self.broadcast.bid, @"Intention": userDict[@"intention"]}];

            [[BroadcastQueueModel sharedInstance] sendUpdateForBroadcastId:self.broadcast.bid withDictionary:userDict];
        }
        
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

@end
