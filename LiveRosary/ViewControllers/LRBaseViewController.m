//
//  LRBaseViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/12/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRBaseViewController.h"
#import "MMDrawerBarButtonItem.h"
#import <mach/mach.h>
#import <mach/mach_host.h>

@interface LRBaseViewController ()

@property (nonatomic) CFTimeInterval screenAppearTime;

@end

@implementation LRBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorFromHexString:@"#dcdcd8"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.screenAppearTime = CACurrentMediaTime();
    [[AnalyticsManager sharedManager] screen:[self screenName]];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[AnalyticsManager sharedManager] event:@"TimeOnScreen" info:@{ @"ScreenName": [self screenName], @"Time": @(CACurrentMediaTime() - self.screenAppearTime)}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    unsigned long appMemory = 0;
    if(kerr == KERN_SUCCESS)
    {
        appMemory = info.resident_size;
    }
    
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    
    vm_statistics_data_t vm_stat;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"Failed to fetch vm statistics");
    }
    
    /* Stats in bytes */
    unsigned long mem_used = (vm_stat.active_count +
                          vm_stat.inactive_count +
                          vm_stat.wire_count) * pagesize;
    unsigned long mem_free = vm_stat.free_count * pagesize;
    unsigned long mem_total = mem_used + mem_free;
    
    [[AnalyticsManager sharedManager] event:@"MemoryWarning" info:@{ @"ScreenName": [self screenName],
                                                                     @"AppMemory": @(appMemory),
                                                                     @"SysMemoryTotal": @(mem_total),
                                                                     @"SysMemoryUsed": @(mem_used),
                                                                     @"SysMemoryFree": @(mem_free)}];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)addDrawerButton
{
    MMDrawerBarButtonItem* button = [[MMDrawerBarButtonItem alloc] initWithTarget:[[UIApplication sharedApplication] delegate] action:@selector(onDrawerButton:)];
    button.tintColor = [UIColor colorFromHexString:@"#3eabd5"];
    [self.navigationItem setLeftBarButtonItem:button];
}

- (NSString*)screenName
{
    NSAssert(NO, @"Must override screenName!");
    return nil;
}

@end
