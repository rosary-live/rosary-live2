//
//  LRBroadcastMainViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/13/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRBroadcastMainViewController.h"
#import "ScheduleManager.h"
#import "ScheduleSingleCell.h"
#import "NSNumber+Utilities.h"
#import "LRScheduleBroadcastViewController.h"
#import "UserManager.h"

@interface LRBroadcastMainViewController () <UITableViewDataSource, UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, weak) IBOutlet UIButton* startBroadcasting;
@property (nonatomic, weak) IBOutlet UITextField* language;

@property (nonatomic, strong) UIPickerView* languagePickerView;

@property (nonatomic, strong) NSMutableArray<NSString*>* languages;
@property (nonatomic, strong) NSArray<ScheduleModel*>* scheduledBroadcasts;

@end

@implementation LRBroadcastMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self addDrawerButton];
    [self addLanguagePickerView];
    
    self.startBroadcasting.layer.cornerRadius = 4;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Add"] style:UIBarButtonItemStylePlain target:self action:@selector(onAdd:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self update];
}

- (void)update {
    if([[UserManager sharedManager] isLoggedIn]) {
        [[ScheduleManager sharedManager] myScheduledBroadcastsWithCompletion:^(NSArray<ScheduleModel *> *scheduledBroadcasts, NSError *error) {
            self.scheduledBroadcasts = scheduledBroadcasts;
            [self filterScheduledBroadcasts];
            [self sortScheduledBroadcasts];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
    }
}

- (NSString*)screenName
{
    return @"Broadcast Main";
}

- (IBAction)onAdd:(id)sender {
    [self performSegueWithIdentifier:@"ToSchedule" sender:sender];
}

- (void)updateScreen {
    [[ScheduleManager sharedManager] clearCache];
    [self update];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([sender isKindOfClass:[UITableViewCell class]])
    {
        LRScheduleBroadcastViewController* scheduleBroadcastViewController = [segue destinationViewController];
        NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
        scheduleBroadcastViewController.scheduledBroadcast = self.scheduledBroadcasts[indexPath.row];
    }
}

- (void)sortScheduledBroadcasts
{
    NSSortDescriptor* byDate = [NSSortDescriptor sortDescriptorWithKey:@"nextScheduledBroadcast" ascending:YES];
    self.scheduledBroadcasts = [self.scheduledBroadcasts sortedArrayUsingDescriptors:@[byDate]];
}

- (void)filterScheduledBroadcasts
{
    NSPredicate* filter = [NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return ((ScheduleModel*)evaluatedObject).isActive;
    }];
    
    self.scheduledBroadcasts = [self.scheduledBroadcasts filteredArrayUsingPredicate:filter];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.scheduledBroadcasts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ScheduleSingleCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ScheduleCell" forIndexPath:indexPath];
    
    ScheduleModel* schedule = self.scheduledBroadcasts[indexPath.row];

    if(schedule.isSingle)
    {
        cell.schedule.text = [NSString stringWithFormat:@"%@ %@", [NSDateFormatter localizedStringFromDate:[schedule.start dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], [NSDateFormatter localizedStringFromDate:[schedule.start dateForNumber] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle]];
    }
    else
    {
        cell.schedule.text = [NSString stringWithFormat:@"From %@ to %@\n%@ at %@", [NSDateFormatter localizedStringFromDate:[schedule.from dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], [NSDateFormatter localizedStringFromDate:[schedule.to dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], [schedule.days daysString], [schedule.at time]];
    }
    
    if([[ScheduleManager sharedManager] reminderSetForBroadcastWithId:schedule.sid]) {
        [cell.alarm setImage:[UIImage imageNamed:@"AlarmOnBlue"] forState:UIControlStateNormal];
    } else {
        [cell.alarm setImage:[UIImage imageNamed:@"AlarmOffBlue"] forState:UIControlStateNormal];
    }
    
    [cell.alarm bk_addEventHandler:^(id sender) {
        if([[ScheduleManager sharedManager] reminderSetForBroadcastWithId:schedule.sid]) {
            [[ScheduleManager sharedManager] removeReminderForScheduledBroadcast:schedule];
        } else {
            [[ScheduleManager sharedManager] addReminderForScheduledBroadcast:schedule broadcaster:YES];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } forControlEvents:UIControlEventTouchUpInside];
    
    [cell.remove bk_addEventHandler:^(id sender) {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:@"Do you really want to delete the scheduled broadcast?" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[ScheduleManager sharedManager] removeScheduledBroadcastWithId:schedule.sid completion:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(error != nil) {
                        [UIAlertView bk_alertViewWithTitle:nil message:@"Unabled to delete schedule broadcast."];
                    } else {
                        [[ScheduleManager sharedManager] removeReminderForScheduledBroadcast:schedule];
                        [self update];
                    }
                });
            }];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    } forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (IBAction)onLanguagePickerDone:(id)sender
{
    [self.language resignFirstResponder];
}

-(void)addLanguagePickerView
{
    self.languages = [[UserManager sharedManager].languages mutableCopy];
    
    self.languagePickerView = [[UIPickerView alloc] init];
    self.languagePickerView.dataSource = self;
    self.languagePickerView.delegate = self;
    self.languagePickerView.showsSelectionIndicator = YES;
    
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Done" style:UIBarButtonItemStyleDone
                                   target:self action:@selector(onLanguagePickerDone:)];
    
    UIToolbar* toolBar = [[UIToolbar alloc] initWithFrame:
                          CGRectMake(0, self.view.frame.size.height-
                                     self.languagePickerView.frame.size.height-50, 320, 50)];
    
    [toolBar setBarStyle:UIBarStyleBlackOpaque];
    NSArray *toolbarItems = [NSArray arrayWithObjects:doneButton, nil];
    [toolBar setItems:toolbarItems];
    self.language.inputView = self.languagePickerView;
    self.language.inputAccessoryView = toolBar;
    self.language.text = [UserManager sharedManager].currentUser.language;
    [UserManager sharedManager].broadcastLanguage = self.language.text;
    
    [self.languagePickerView selectRow:[self.languages indexOfObject:[UserManager sharedManager].currentUser.language] inComponent:0 animated:NO];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.languages.count;
}

#pragma mark - UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self.language setText:[self.languages objectAtIndex:row]];
    [UserManager sharedManager].broadcastLanguage = [self.languages objectAtIndex:row];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.languages objectAtIndex:row];
}

@end
