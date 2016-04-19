//
//  BroadcastsViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 3/5/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "BroadcastsViewController.h"
#import "BroadcastCell.h"
#import "UserManager.h"
#import "BroadcastManager.h"
#import "DBBroadcast.h"
#import "DBReportedBroadcast.h"
#import "NSNumber+Utilities.h"
#import <MapKit/MapKit.h>
#import "INTULocationManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "ViewScheduleSingleCell.h"
#import "ScheduleManager.h"
#import "ReportCell.h"
#import "ReportedBroadcastModel.h"

typedef NS_ENUM(NSUInteger, Section) {
    SectionBroadcasts,
    SectionScheduledBroadcasts
};

typedef NS_ENUM(NSUInteger, Mode) {
    ModeList,
    ModeMap
};

@interface BroadcastsViewController () <UITableViewDataSource, UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, weak) IBOutlet MKMapView* mapView;
@property (nonatomic, weak) IBOutlet UITextField* language;
@property (nonatomic, weak) IBOutlet UISegmentedControl* modeSegmentControl;

@property (nonatomic, strong) UIPickerView* languagePickerView;

@property (nonatomic, strong) NSArray<BroadcastModel *>* fullBroadcasts;
@property (nonatomic, strong) NSArray<BroadcastModel *>* broadcasts;

@property (nonatomic, strong) NSArray<ReportedBroadcastModel *>* fullReportedBroadcasts;
@property (nonatomic, strong) NSArray<ReportedBroadcastModel *>* reportedBroadcasts;

@property (nonatomic, strong) NSArray<ScheduleModel *>* fullScheduledBroadcasts;
@property (nonatomic, strong) NSArray<ScheduleModel *>* scheduledBroadcasts;

@property (nonatomic, strong) NSMutableArray<NSString*>* languages;
@property (nonatomic, strong) CLLocation* currentLocation;

@end

@implementation BroadcastsViewController

+ (instancetype)instantiate
{
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BroadcastsViewController"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    [self addLanguagePickerView];
    [self centerMapView];
        
//    if([UserManager sharedManager].isLoggedIn)
//    {
//        [self update];
//    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)addLanguagePickerView
{
    self.languages = [[UserManager sharedManager].languages mutableCopy];
    [self.languages insertObject:ALL_LANGUAGES atIndex:0];
    
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
    
    [self.languagePickerView selectRow:[self.languages indexOfObject:self.language.text] inComponent:0 animated:NO];
}

- (void)update
{
    if(self.showReportedBroadcasts)
    {
        [self updateReportedBroadcasts];
    }
    else
    {
        [self updateBroadcasts];
        [self updateScheduledBroadcasts];
    }
}

- (void)updateBroadcasts
{
    [[DBBroadcast sharedInstance] updateBroadcastsWithCompletion:^(NSArray<BroadcastModel *> *broadcasts, NSError *error) {
        self.fullBroadcasts = broadcasts;
        [self filterBroadcasts];
        [self sortBroadcasts];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self addMapPins];
        });
    }];
}

- (void)updateScheduledBroadcasts
{
    [[ScheduleManager sharedManager] allScheduledBroadcastsWithCompletion:^(NSArray<ScheduleModel *> *scheduledBroadcasts, NSError *error) {
        self.fullScheduledBroadcasts = scheduledBroadcasts;
        [self filterScheduledBroadcasts];
        [self sortScheduledBroadcasts];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self addMapPins];
        });
    }];
}

- (void)updateReportedBroadcasts
{
    [[DBReportedBroadcast sharedInstance] updateReportedBroadcastsWithCompletion:^(NSArray<ReportedBroadcastModel *> *broadcasts, NSError *error) {
        self.fullReportedBroadcasts = broadcasts;
        [self filterReportedBroadcasts];
        [self sortReportedBroadcasts];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self addMapPins];
        });
    }];
}

- (void)sortBroadcasts
{
    NSSortDescriptor* byDate = [NSSortDescriptor sortDescriptorWithKey:@"created" ascending:YES];
    self.broadcasts = [self.broadcasts sortedArrayUsingDescriptors:@[byDate]];
}

- (void)filterBroadcasts
{
    self.broadcasts = [self.fullBroadcasts copy];

    if(self.liveOnly)
    {
        NSPredicate* filter = [NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return ((BroadcastModel*)evaluatedObject).isLive;
        }];
        
        self.broadcasts = [self.broadcasts filteredArrayUsingPredicate:filter];
    }

    // Language filter
    if(![self.language.text isEqualToString:ALL_LANGUAGES])
    {
        NSPredicate* filter = [NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [((BroadcastModel*)evaluatedObject).language isEqualToString:self.language.text];
        }];
        
        self.broadcasts = [self.broadcasts filteredArrayUsingPredicate:filter];
    }
}

- (void)sortScheduledBroadcasts
{
    NSSortDescriptor* byDate = [NSSortDescriptor sortDescriptorWithKey:@"nextScheduledBroadcast" ascending:YES];
    self.scheduledBroadcasts = [self.scheduledBroadcasts sortedArrayUsingDescriptors:@[byDate]];
}

- (void)filterScheduledBroadcasts
{
    self.scheduledBroadcasts = [self.fullScheduledBroadcasts copy];
    
    if(!self.allScheduledBroadcasts)
    {
        NSPredicate* filter = [NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return ((ScheduleModel*)evaluatedObject).isActive && ![((ScheduleModel*)evaluatedObject).user isEqualToString:[UserManager sharedManager].email];
        }];
        
        self.scheduledBroadcasts = [self.scheduledBroadcasts filteredArrayUsingPredicate:filter];
    }
    
    // Language filter
    if(![self.language.text isEqualToString:ALL_LANGUAGES])
    {
        NSPredicate* filter = [NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [((ScheduleModel*)evaluatedObject).language isEqualToString:self.language.text];
        }];
        
        self.scheduledBroadcasts = [self.scheduledBroadcasts filteredArrayUsingPredicate:filter];
    }
}

- (void)sortReportedBroadcasts
{
    NSSortDescriptor* byBroadcastId = [NSSortDescriptor sortDescriptorWithKey:@"bid" ascending:YES];
    NSSortDescriptor* byDate = [NSSortDescriptor sortDescriptorWithKey:@"created" ascending:YES];
    self.reportedBroadcasts = [self.reportedBroadcasts sortedArrayUsingDescriptors:@[byBroadcastId, byDate]];
}

- (void)filterReportedBroadcasts
{
    self.reportedBroadcasts = [self.fullReportedBroadcasts copy];
}

- (void)addMapPins
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    if(self.showReportedBroadcasts)
    {
        for(ReportedBroadcastModel* broadcast in self.reportedBroadcasts)
        {
            [self.mapView addAnnotation:broadcast];
        }
    }
    else
    {
        for(BroadcastModel* broadcast in self.broadcasts)
        {
            [self.mapView addAnnotation:broadcast];
        }
        
        for(ScheduleModel* schedule in self.scheduledBroadcasts)
        {
            [self.mapView addAnnotation:schedule];
        }
    }
}

- (IBAction)onLanguagePickerDone:(id)sender
{
    [self.language resignFirstResponder];
}

- (IBAction)onModeChange:(id)sender
{
    Mode mode = [self.modeSegmentControl selectedSegmentIndex];
    switch(mode)
    {
        case ModeList:
            [self changeToListMode];
            break;
            
        case ModeMap:
            [self changeToMapMode];
            break;
    }
}

- (void)changeToListMode
{
    self.tableView.hidden = NO;
    self.mapView.hidden = YES;
}

- (void)changeToMapMode
{
    self.tableView.hidden = YES;
    self.mapView.hidden = NO;
}

- (void)centerMapView
{
    INTULocationManager* locMgr = [INTULocationManager sharedInstance];
    [locMgr requestLocationWithDesiredAccuracy:INTULocationAccuracyCity
                                       timeout:10.0
                          delayUntilAuthorized:YES  // This parameter is optional, defaults to NO if omitted
                                         block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                                             if (status == INTULocationStatusSuccess) {
                                                 self.currentLocation = currentLocation;
                                                 
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     MKCoordinateRegion region;
                                                     region.center = self.currentLocation.coordinate;
                                                     
                                                     MKCoordinateSpan span;
                                                     span.latitudeDelta  = 1;
                                                     span.longitudeDelta = 1;
                                                     region.span = span;
                                                     
                                                     [self.mapView setRegion:region animated:NO];
                                                 });
                                             }
                                             else if (status == INTULocationStatusTimedOut) {
                                                 // Wasn't able to locate the user with the requested accuracy within the timeout interval.
                                                 // However, currentLocation contains the best location available (if any) as of right now,
                                                 // and achievedAccuracy has info on the accuracy/recency of the location in currentLocation.
                                             }
                                             else {
                                                 // An error occurred, more info is available by looking at the specific status returned.
                                             }
                                         }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(self.showReportedBroadcasts)
    {
        return 1;
    }
    else
    {
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section)
    {
        case SectionBroadcasts:
            return self.showReportedBroadcasts ? self.reportedBroadcasts.count : self.broadcasts.count;
            
        case SectionScheduledBroadcasts:
            return self.scheduledBroadcasts.count;
            
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section)
    {
        case SectionBroadcasts:
            return self.showReportedBroadcasts ? @"Reported Broadcasts" : @"Live Broadcasts";
            
        case SectionScheduledBroadcasts:
            return @"Scheduled Broadcasts";
            
        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.section)
    {
        case SectionBroadcasts:
        {
            if(self.showReportedBroadcasts)
            {
                ReportCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ReportCell"];
                
                ReportedBroadcastModel* report = self.reportedBroadcasts[indexPath.row];
                cell.name.text = report.b_name;
                cell.language.text = report.b_language;
                cell.date.text = [NSString stringWithFormat:@" %@ %@", [NSDateFormatter localizedStringFromDate:[report.created dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], [NSDateFormatter localizedStringFromDate:[report.created dateForNumber] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle]];
                cell.reporter.text = [NSString stringWithFormat:@"By: %@ (%@)", report.r_name, report.r_email];
                cell.reason.text = report.reason;
                
                NSString* urlString = [NSString stringWithFormat:@"https://s3.amazonaws.com/liverosaryavatars/%@", [report.b_email stringByReplacingOccurrencesOfString:@"@" withString:@"-"]];
                [cell.avatar sd_setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:[UIImage imageNamed:@"AvatarImage"] options:0];
                
                return cell;
            }
            else
            {
                BroadcastCell* cell = [tableView dequeueReusableCellWithIdentifier:@"BroadcastCell"];
                
                BroadcastModel* broadcast = self.broadcasts[indexPath.row];
                cell.name.text = broadcast.name;
                cell.language.text = broadcast.language;
                cell.location.text = [NSString stringWithFormat:@"%@, %@ %@", broadcast.city, broadcast.state, broadcast.country];
                cell.date.text = [NSString stringWithFormat:@" %@ %@", [NSDateFormatter localizedStringFromDate:[broadcast.updated dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], [NSDateFormatter localizedStringFromDate:[broadcast.updated dateForNumber] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle]];
                cell.live.text = broadcast.isLive ? @"LIVE" : @"ENDED";
                
                NSString* urlString = [NSString stringWithFormat:@"https://s3.amazonaws.com/liverosaryavatars/%@", [broadcast.user stringByReplacingOccurrencesOfString:@"@" withString:@"-"]];
                [cell.avatar sd_setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:[UIImage imageNamed:@"AvatarImage"] options:0];
                
                return cell;
            }
        }
            
        case SectionScheduledBroadcasts:
        {
            ViewScheduleSingleCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ViewScheduledBroadcastCell"];
            
            ScheduleModel* scheduledBroadcast = self.scheduledBroadcasts[indexPath.row];
            cell.name.text = scheduledBroadcast.name;
            cell.language.text = scheduledBroadcast.language;
            cell.location.text = [NSString stringWithFormat:@"%@, %@ %@", scheduledBroadcast.city, scheduledBroadcast.state, scheduledBroadcast.country];
            
            if(scheduledBroadcast.isSingle)
            {
                cell.schedule.text = [NSString stringWithFormat:@"%@ %@", [NSDateFormatter localizedStringFromDate:[scheduledBroadcast.start dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], [NSDateFormatter localizedStringFromDate:[scheduledBroadcast.start dateForNumber] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle]];
            }
            else
            {
                cell.schedule.text = [NSString stringWithFormat:@"From %@ to %@\n%@ at %@", [NSDateFormatter localizedStringFromDate:[scheduledBroadcast.from dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], [NSDateFormatter localizedStringFromDate:[scheduledBroadcast.to dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], [scheduledBroadcast.days daysString], [scheduledBroadcast.at time]];
            }
            
            NSString* urlString = [NSString stringWithFormat:@"https://s3.amazonaws.com/liverosaryavatars/%@", [scheduledBroadcast.user stringByReplacingOccurrencesOfString:@"@" withString:@"-"]];
            [cell.avatarImage sd_setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:[UIImage imageNamed:@"AvatarImage"] options:0];
            
            if([ScheduleManager sharedManager].notificationsEnabled)
            {
                cell.reminderButton.hidden = NO;
                UIImage* image = [[ScheduleManager sharedManager] reminderSetForBroadcastWithId:scheduledBroadcast.sid] ? [UIImage imageNamed:@"AlarmOn"] : [UIImage imageNamed:@"AlarmOff"];
                [cell.reminderButton setImage:image forState:UIControlStateNormal];
                [cell.reminderButton addTarget:self action:@selector(onReminder:) forControlEvents:UIControlEventTouchUpInside];
                cell.reminderButton.tag = indexPath.row;
            }
            else
            {
                cell.reminderButton.hidden = YES;
            }
            
            return cell;
        }
            
        default:
            return nil;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.showReportedBroadcasts)
    {
        return 100.0f;
    }
    else
    {
        return 70.0f;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == SectionBroadcasts)
    {
        if(self.showReportedBroadcasts)
        {
            [self reportedBroadcastSelected:self.reportedBroadcasts[indexPath.row]];
        }
        else
        {
            [self broadcastSelected:self.broadcasts[indexPath.row]];
        }
    }
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
    [self filterBroadcasts];
    [self filterScheduledBroadcasts];
    [self.tableView reloadData];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.languages objectAtIndex:row];
}

#pragma mark - MKMapViewDelegate

#pragma mark MKMapView delegate
- (MKAnnotationView *)mapView:(MKMapView *)mapview viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        return nil;
    }
    
    static NSString* AnnotationIdentifier = @"AnnotationIdentifier";
    MKAnnotationView *annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
    if(annotationView)
    {
        return annotationView;
    }
    else
    {
       annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
    }
    
    if([annotation isKindOfClass:[BroadcastModel class]])
    {
        if(((BroadcastModel*)annotation).isLive)
        {
            annotationView.image = [UIImage imageNamed:@"LiveMapPin"];
        }
        else
        {
            annotationView.image = [UIImage imageNamed:@"EndedMapPin"];
        }
    }
    else
    {
        annotationView.image = [UIImage imageNamed:@"FutureMapPin"];
    }
    
    UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [rightButton addTarget:self action:@selector(onMapPinSelected:) forControlEvents:UIControlEventTouchUpInside];
    [rightButton setTitle:annotation.title forState:UIControlStateNormal];
    annotationView.rightCalloutAccessoryView = rightButton;
    annotationView.canShowCallout = YES;
    annotationView.draggable = NO;
    annotationView.centerOffset = CGPointMake(0.0f, -18.0f);
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    NSLog(@"didSelectAnnotationView");
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    NSLog(@"calloutAccessoryControlTapped");
    [self broadcastSelected:(BroadcastModel*)view.annotation];
}

- (IBAction)onMapPinSelected:(id)sender
{
    NSLog(@"onMapPinSelected %@", sender);
}

- (void)broadcastSelected:(BroadcastModel*)broadcast
{
    if(self.delegate != nil && [self.delegate respondsToSelector:@selector(selectedBroadcast:)])
    {
        [self.delegate selectedBroadcast:broadcast];
    }
}

- (void)reportedBroadcastSelected:(ReportedBroadcastModel*)broadcast
{
    if(self.delegate != nil && [self.delegate respondsToSelector:@selector(selectedReportedBroadcast:)])
    {
        [self.delegate selectedReportedBroadcast:broadcast];
    }
}

- (IBAction)onReminder:(id)sender
{
    NSInteger row = ((UIView*)sender).tag;
    
    ScheduleModel* schedule = self.scheduledBroadcasts[row];
    if([[ScheduleManager sharedManager] reminderSetForBroadcastWithId:schedule.sid])
    {
        [[ScheduleManager sharedManager] removeReminderForScheduledBroadcast:schedule];
    }
    else
    {
        [[ScheduleManager sharedManager] addReminderForScheduledBroadcast:schedule broadcaster:NO];
    }
    
    [self.tableView reloadData];
}

@end
