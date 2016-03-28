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
#import "TestFairy.h"

#import "TransferManager.h"

@interface AppDelegate ()

@property (nonatomic,strong) MMDrawerController* drawerController;

@end

@implementation AppDelegate

-(BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
//    [DDLog addLogger:[DDTTYLogger sharedInstance]];
//    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    
    [TestFairy begin:@"af61a53a28663c4531a8f85810786c236aca5908"];
    
    DDLogInfo(@"App Startup");
    
    LRDrawerViewController* drawerViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"DrawerViewController"];
    
    drawerViewController.listenMainViewController = (UINavigationController*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Listen"];
    drawerViewController.broadcastMainViewController = (UINavigationController*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Broadcast"];
    drawerViewController.adminMainViewController = (UINavigationController*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Admin"];
    drawerViewController.userProfileMainMainViewController = (UINavigationController*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"UserProfile"];
    
    self.drawerController = [[MMDrawerController alloc]
                             initWithCenterViewController:drawerViewController.listenMainViewController
                             leftDrawerViewController:drawerViewController];
    [self.drawerController setShowsShadow:YES];
    [self.drawerController setMaximumRightDrawerWidth:200.0];
    [self.drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeAll];
    [self.drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:self.drawerController];
    
    [self updateConfigFromServer];
    [[ScheduleManager sharedManager] configureNotifications];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[TransferManager sharedManager] checkBroadcastBandwidthWithCompletion:^(double averageBytesPerSecond) {
//            NSLog(@"averageBytesPerSecond: %g", averageBytesPerSecond);
//        }];
    
//        [[TransferManager sharedManager] checkListenBandwidthWithCompletion:^(double averageBytesPerSecond) {
//            NSLog(@"averageBytesPerSecond: %g", averageBytesPerSecond);
//        }];
//    });
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

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
        DDLogInfo(@"Got config: compressionBitRat: %d  maxBroadcastSeconds: %d  sampleRate: %d  segmentSizeSeconds: %d", (int)[ConfigModel sharedInstance].compressionBitRate, (int)[ConfigModel sharedInstance].maxBroadcastSeconds, (int)[ConfigModel sharedInstance].sampleRate, (int)[ConfigModel sharedInstance].segmentSizeSeconds);
    }];
}

- (IBAction)onDrawerButton:(id)sender
{
    [self.drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:^(BOOL finished) {
        DDLogDebug(@"Drawer Toggle now %@", self.drawerController.openSide == MMDrawerSideNone ? @"Closed" : @"Open");
    }];
}

@end
