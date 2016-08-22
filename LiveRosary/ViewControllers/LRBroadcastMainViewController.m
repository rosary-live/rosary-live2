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
    
    [[ScheduleManager sharedManager] myScheduledBroadcastsWithCompletion:^(NSArray<ScheduleModel *> *scheduledBroadcasts, NSError *error) {
        self.scheduledBroadcasts = scheduledBroadcasts;
        [self filterScheduledBroadcasts];
        [self sortScheduledBroadcasts];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)screenName
{
    return @"Broadcast Main";
}

- (IBAction)onAdd:(id)sender {
    [self performSegueWithIdentifier:@"ToSchedule" sender:sender];
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
