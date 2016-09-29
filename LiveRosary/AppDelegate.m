//
//  AppDelegate.m
//  LiveRosary
//
//  Created by richardtaylor on 1/11/16.
//  Copyright © 2016 Pocket Cake. All rights reserved.
//

#import "AppDelegate.h"
#import "MMDrawerController.h"
#import "LRDrawerViewController.h"
#import "LRListenMainViewController.h"
#import "ScheduleManager.h"
#import "UserManager.h"
#import "TestFairy.h"
#import "Branch.h"
#import "AnalyticsManager.h"
#import <AFNetworking/AFNetworking.h>

@interface AppDelegate () <DrawerButtonDelegate>

@property (nonatomic, strong) MMDrawerController* drawerController;
@property (nonatomic, strong) LRDrawerViewController* drawerViewController;
@property (nonatomic, strong) UIView* noNetworkView;
@property (nonatomic) BOOL startupComplete;
@property (nonatomic, strong) NSURL* deepLinkURL;

@end

@implementation AppDelegate

-(BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
//    [DDLog addLogger:[DDTTYLogger sharedInstance]];
//    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    
    [TestFairy begin:@"af61a53a28663c4531a8f85810786c236aca5908"];
    
    DDLogInfo(@"App Startup");
    
    [self setupAppearence];
    
    self.drawerViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"DrawerViewController"];
    
    self.drawerViewController.listenMainViewController = (UINavigationController*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Listen"];
    
    self.drawerViewController.broadcastMainViewController = (UINavigationController*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Broadcast"];

    self.drawerViewController.broadcastRequestViewController = (UINavigationController*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BroadcastRequest"];

    
    self.drawerViewController.adminMainViewController = (UINavigationController*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Admin"];
    self.drawerViewController.userProfileMainMainViewController = (UINavigationController*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"UserProfile"];
    
    self.drawerController = [[MMDrawerController alloc]
                             initWithCenterViewController:self.drawerViewController.listenMainViewController
                             leftDrawerViewController:self.drawerViewController];
    [self.drawerController setShowsShadow:YES];
    [self.drawerController setMaximumRightDrawerWidth:200.0];
    [self.drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModePanningNavigationBar];
    [self.drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModePanningNavigationBar];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:self.drawerController];
    
    [[ScheduleManager sharedManager] configureNotifications];
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSLog(@"Reachability: %@", AFStringFromNetworkReachabilityStatus(status));
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(status == AFNetworkReachabilityStatusNotReachable)
            {
                self.noNetworkView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
                self.noNetworkView.backgroundColor = [UIColor blackColor];
                self.noNetworkView.alpha = 0.6;
                UILabel* message = [[UILabel alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width/2 - 150, [[UIScreen mainScreen] bounds].size.height/2 - 150, 300, 300)];
                message.font = [UIFont fontWithName:message.font.fontName size:20];
                message.text = @"An internet connection is required. Please reconnect to the internet.";
                message.numberOfLines = 0;
                message.clipsToBounds = YES;
                message.lineBreakMode = NSLineBreakByWordWrapping;
                message.textColor = [UIColor whiteColor];
                message.textAlignment = NSTextAlignmentCenter;
                [self.noNetworkView addSubview:message];
                [self.window.rootViewController.view addSubview:self.noNetworkView];
            }
            else if(status != AFNetworkReachabilityStatusUnknown)
            {
                if(self.noNetworkView != nil)
                {
                    [self.noNetworkView removeFromSuperview];
                    self.noNetworkView = nil;
                }
            }
        });
    }];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    self.startupComplete = YES;
    
    if(self.deepLinkURL != nil) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.drawerViewController showPasswordReset];
        });        
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //[AWSLogger defaultLogger].logLevel = AWSLogLevelVerbose;
    [AnalyticsManager sharedManager];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn) name:NotificationUserLoggedIn object:nil];

//    Branch *branch = [Branch getInstance];
//    [branch initSessionWithLaunchOptions:launchOptions andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
//        // params are the deep linked params associated with the link that the user clicked before showing up.
//        NSLog(@"deep link data: %@", [params description]);
//        
//        NSNumber* branchLinkClicked = params[@"+clicked_branch_link"];
//        if(branchLinkClicked != nil && branchLinkClicked.boolValue)
//        {
//            NSString* identifier = params[@"$canonical_identifier"];
//            if([identifier isEqualToString:@"LostPassword"])
//            {
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    [self.drawerViewController showPasswordReset];
//                });
//            }
//        }
//    }];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
//    [[Branch getInstance] handleDeepLink:url];
    
    if([url.host isEqualToString:@"forgotPassword"]) {
        if(self.startupComplete) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.drawerViewController showPasswordReset];
            });
        } else {
            self.deepLinkURL = url;
        }
    }
    
    return YES;
}

//- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
//    [[Branch getInstance] continueUserActivity:userActivity];
//    return YES;
//}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    [[ScheduleManager sharedManager] configureNotifications];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [self updateConfigFromServer];
    [[ScheduleManager sharedManager] cleanupNotifications];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"Notification: %@ %@", notification, notification.userInfo);
    [[ScheduleManager sharedManager] handleLocalNotification:notification];
}

- (void)updateConfigFromServer
{
    [[ConfigModel sharedInstance] loadConfigWithCompletion:^(NSError *error) {
        DDLogInfo(@"Got config:  maxBroadcastSeconds: %d  sampleRate: %d  segmentSizeSeconds: %d", (int)[ConfigModel sharedInstance].maxBroadcastSeconds, (int)[ConfigModel sharedInstance].sampleRate, (int)[ConfigModel sharedInstance].segmentSizeSeconds);
    }];
}

- (IBAction)onDrawerButton:(id)sender
{
    [self.drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:^(BOOL finished) {
        DDLogDebug(@"Drawer Toggle now %@", self.drawerController.openSide == MMDrawerSideNone ? @"Closed" : @"Open");
    }];
}

- (void)userLoggedIn
{
    if([UserManager sharedManager].currentUser.userLevel == UserLevelBanned)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIAlertView bk_showAlertViewWithTitle:@"Banned" message:@"Your account has been banned." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                exit(0);
            }];
        });
    }
}

- (void)setupAppearence {
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorFromHexString:@"#2f3d74"]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor],
                                                           NSFontAttributeName: [UIFont fontWithName:@"Rokkitt" size:26.0f]}];
    
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navigation.png"]
                                       forBarMetrics:UIBarMetricsDefault];

//    NSShadow *shadow = [[NSShadow alloc] init];
//    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
//    shadow.shadowOffset = CGSizeMake(0, 1);
//    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
//                                                           [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
//                                                           shadow, NSShadowAttributeName,
//                                                           [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:21.0], NSFontAttributeName, nil]];
    
    [[UIButton appearance] setTintColor:[UIColor colorFromHexString:@"#344479"]];
    //[[UIButton appearance] setFont:[UIFont fontWithName:@"Veranda" size:14]];
    
    //[[UITextField appearance] setFont:[UIFont fontWithName:@"Veranda" size:12]];
    
    //[[UILabel appearance] setFont:[UIFont fontWithName:@"Veranda" size:10]];
}

@end
