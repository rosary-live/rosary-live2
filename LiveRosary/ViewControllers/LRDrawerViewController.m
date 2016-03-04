//
//  LRDrawerViewController.m
//  LiveRosary
//
//  Created by richardtaylor on 1/11/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRDrawerViewController.h"
#import "DrawerCell.h"
#import "UIViewController+MMDrawerController.h"
#import "UserManager.h"

@interface LRDrawerViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIImageView* avatarImageView;
@property (nonatomic, weak) IBOutlet UILabel* firstName;
@property (nonatomic, weak) IBOutlet UILabel* lastName;
@property (nonatomic, weak) IBOutlet UILabel* language;
@property (nonatomic, weak) IBOutlet UITableView* tableView;

@end

@implementation LRDrawerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Start authentication if user isn't logged in
    if(![UserManager sharedManager].isLoggedIn)
    {
        [self showAuthentication];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedOut) name:NotificationUserLoggedOut object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if([UserManager sharedManager].currentUser != nil)
    {
        self.avatarImageView.image = [UserManager sharedManager].avatarImage;
        self.firstName.text = [UserManager sharedManager].currentUser.firstName;
        self.lastName.text = [UserManager sharedManager].currentUser.lastName;
        self.language.text = [UserManager sharedManager].currentUser.language;
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

- (void)userLoggedOut
{
    [self showAuthentication];
}

- (void)showAuthentication
{
    // Queue it at the end of the main run loop so it happens after the UI has been created.
    dispatch_async(dispatch_get_main_queue(), ^{
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UINavigationController* authNav = [storyboard instantiateViewControllerWithIdentifier:@"Authentication"];
        [self presentViewController:authNav animated:YES completion:nil];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DrawerCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DrawerCell" forIndexPath:indexPath];
    
    BOOL selected = NO;
    switch(indexPath.row)
    {
        case 0:
            if(self.mm_drawerController.centerViewController == self.listenMainViewController) selected = YES;
            cell.title.text = @"Listen";
            break;
            
        case 1:
            if(self.mm_drawerController.centerViewController == self.broadcastMainViewController) selected = YES;
            cell.title.text = @"Broadcast";
            break;
            
        case 2:
            if(self.mm_drawerController.centerViewController == self.adminMainViewController) selected = YES;
            cell.title.text = @"Admin";
            break;
            
        case 3:
            if(self.mm_drawerController.centerViewController == self.userProfileMainMainViewController) selected = YES;
            cell.title.text = @"User Profile";
            break;
    }
    
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.selected = selected;
        });
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView.visibleCells bk_all:^BOOL(DrawerCell* cell) {
        cell.selected = NO;
        return YES;
    }];
    
    UIViewController* centerViewController;
    switch(indexPath.row)
    {
        case 0:
            centerViewController = self.listenMainViewController;
            break;
            
        case 1:
            centerViewController = self.broadcastMainViewController;
            break;
            
        case 2:
            centerViewController = self.adminMainViewController;
            break;
            
        case 3:
            centerViewController = self.userProfileMainMainViewController;
            break;
    }
    
    @weakify(self);
    [self.mm_drawerController setCenterViewController:centerViewController withCloseAnimation:YES completion:^(BOOL finished) {
        @strongify(self);
        [self.tableView reloadData];
    }];
}

@end
