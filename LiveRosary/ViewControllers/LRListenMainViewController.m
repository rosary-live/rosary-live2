//
//  LRListenMainViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/11/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRListenMainViewController.h"
#import "LRListenViewController.h"
#import "UserManager.h"
#import "BroadcastManager.h"
#import "DBBroadcast.h"
#import "BroadcastCell.h"
#import "NSNumber+Utilities.h"
#import "BroadcastsTableView.h"
#import <MapKit/MapKit.h>
#import "INTULocationManager.h"

typedef NS_ENUM(NSUInteger, Mode) {
    ModeList,
    ModeMap
};

@interface LRListenMainViewController () <BroadcastsTableViewActionDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, weak) IBOutlet BroadcastsTableView* tableView;
@property (nonatomic, weak) IBOutlet UITextField* language;
@property (nonatomic, weak) IBOutlet UISegmentedControl* modeSegmentControl;

@property (nonatomic, strong) MKMapView* mapView;

@property (nonatomic, strong) UIPickerView* languagePickerView;

@property (nonatomic, strong) NSArray<BroadcastModel *> *broadcasts;
@property (nonatomic, strong) NSMutableArray<NSString*>* languages;

@property (nonatomic, strong) CLLocation* currentLocation;

@end

@implementation LRListenMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addDrawerButton];
    [self addLanguagePickerView];
    [self addMapView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self.tableView action:@selector(updateBroadcasts)];
    
    self.tableView.actionDelegate = self;
    self.tableView.liveOnly = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addLanguagePickerView
{
    self.languages = [[UserManager sharedManager].languages mutableCopy];
    [self.languages insertObject:@"All Languages" atIndex:0];
    
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

- (void)addMapView
{
    self.mapView = [[MKMapView alloc] initWithFrame:self.tableView.frame];
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MKUserTrackingModeNone;
    self.mapView.hidden = YES;
    [self.view addSubview:self.mapView];
    
    INTULocationManager* locMgr = [INTULocationManager sharedInstance];
    [locMgr requestLocationWithDesiredAccuracy:INTULocationAccuracyCity
                                       timeout:10.0
                          delayUntilAuthorized:YES  // This parameter is optional, defaults to NO if omitted
                                         block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                                             if (status == INTULocationStatusSuccess) {
                                                 self.currentLocation = currentLocation;
                                                 
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [self centerMapView];
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    LRListenViewController* listenViewController = (LRListenViewController*)segue.destinationViewController;
//    BroadcastCell* cell = (BroadcastCell*)sender;
//    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
//    listenViewController.broadcast = self.broadcasts[indexPath.row];
//    listenViewController.playFromStart = NO;
//}

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
    MKCoordinateRegion region;
    region.center = self.currentLocation.coordinate;
    
    MKCoordinateSpan span;
    span.latitudeDelta  = 1;
    span.longitudeDelta = 1;
    region.span = span;
    
    [self.mapView setRegion:region animated:NO];
}

#pragma mark - BroadcastsTableViewActionDelegate

- (void)selectedBroadcast:(BroadcastModel*)broadcast
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LRListenViewController* listenViewController = [storyboard instantiateViewControllerWithIdentifier:@"LRListenViewController"];
    listenViewController.broadcast = broadcast;
    listenViewController.playFromStart = NO;
    [self.navigationController pushViewController:listenViewController animated:YES];
}

#pragma mark - UIPickerViewDataSource

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.languages.count;
}

#pragma mark - UIPickerViewDelegate

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self.language setText:[self.languages objectAtIndex:row]];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.languages objectAtIndex:row];
}

@end
