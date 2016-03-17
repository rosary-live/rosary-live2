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
#import "NSNumber+Utilities.h"
#import <MapKit/MapKit.h>
#import "INTULocationManager.h"
#import <SDWebImage/UIImageView+WebCache.h>

typedef NS_ENUM(NSUInteger, Mode) {
    ModeList,
    ModeMap
};

//@interface MapAnnotation : NSObject  <MKAnnotation>
//@end
//
//@implementation MapAnnotation
//@end


@interface BroadcastsViewController () <UITableViewDataSource, UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, weak) IBOutlet MKMapView* mapView;
@property (nonatomic, weak) IBOutlet UITextField* language;
@property (nonatomic, weak) IBOutlet UISegmentedControl* modeSegmentControl;

@property (nonatomic, strong) UIPickerView* languagePickerView;

@property (nonatomic, strong) NSArray<BroadcastModel *> *broadcasts;
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBroadcasts) name:NotificationUserLoggedIn object:nil];
    
    if([UserManager sharedManager].isLoggedIn)
    {
        [self updateBroadcasts];
    }
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

- (void)updateBroadcasts
{
    [[DBBroadcast sharedInstance] updateBroadcastsWithCompletion:^(NSArray<BroadcastModel *> *broadcasts, NSError *error) {
        self.broadcasts = broadcasts;
        [self filterBroadcasts];
        [self sortBroadcasts];
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
    if(self.liveOnly)
    {
        NSPredicate* filter = [NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return ((BroadcastModel*)evaluatedObject).isLive;
        }];
        
        self.broadcasts = [self.broadcasts filteredArrayUsingPredicate:filter];
    }
}

- (void)addMapPins
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    for(BroadcastModel* broadcast in self.broadcasts)
    {
        [self.mapView addAnnotation:broadcast];
//        MKPointAnnotation* pin = [[MKPointAnnotation alloc] init];
//        pin.coordinate = CLLocationCoordinate2DMake(broadcast.lat.doubleValue, broadcast.lon.doubleValue);
//        pin.title = [NSString stringWithFormat:@"%@ - %@", broadcast.name, broadcast.language];
//        pin.subtitle = [NSDateFormatter localizedStringFromDate:[broadcast.updated dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
//        [self.mapView addAnnotation:pin];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.broadcasts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BroadcastCell* cell = [tableView dequeueReusableCellWithIdentifier:@"BroadcastCell"];
    
    BroadcastModel* broadcast = self.broadcasts[indexPath.row];
    cell.name.text = broadcast.name;
    cell.language.text = broadcast.language;
    cell.location.text = [NSString stringWithFormat:@"%@, %@ %@", broadcast.city, broadcast.state, broadcast.country];
    cell.date.text = [NSDateFormatter localizedStringFromDate:[broadcast.updated dateForNumber] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    cell.live.text = broadcast.isLive ? @"LIVE" : @"ENDED";
    
    NSString* urlString = [NSString stringWithFormat:@"https://s3.amazonaws.com/liverosaryavatars/%@", [broadcast.user stringByReplacingOccurrencesOfString:@"@" withString:@"-"]];
    [cell.avatar sd_setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:[UIImage imageNamed:@"AvatarImage"] options:0];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self broadcastSelected:self.broadcasts[indexPath.row]];
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
        MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
        if(((BroadcastModel*)annotation).isLive)
        {
            annotationView.image = [UIImage imageNamed:@"LiveMapPin"];
        }
        else
        {
            annotationView.image = [UIImage imageNamed:@"EndedMapPin"];
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
    return nil;
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

@end
