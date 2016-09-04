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
#import "LRResetPasswordViewController.h"

typedef NS_ENUM(NSUInteger, MenuOption) {
    MenuOptionListen,
    MenuOptionBroadcast,
    MenuOptionAdmin,
    MenuOptionProfile
};

@interface LRDrawerViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIImageView* avatarImageView;
@property (nonatomic, weak) IBOutlet UILabel* firstName;
@property (nonatomic, weak) IBOutlet UILabel* lastName;
@property (nonatomic, weak) IBOutlet UILabel* language;
@property (nonatomic, weak) IBOutlet UITableView* tableView;

@property (nonatomic, strong) NSMutableArray* menuOptions;

@property (nonatomic, strong) UINavigationController* authNav;

@end

@implementation LRDrawerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Start authentication if user isn't logged in
    if(![UserManager sharedManager].isLoggedIn)
    {
        [self showAuthenticationWithCompletion:nil];
    }
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedOut) name:NotificationUserLoggedOut object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.menuOptions = [NSMutableArray new];
    
    UserModel* user = [UserManager sharedManager].currentUser;
    if(user != nil)
    {
        self.avatarImageView.image = [UserManager sharedManager].avatarImage;
        self.firstName.text = user.firstName;
        self.lastName.text = user.lastName;
        self.language.text = user.language;
        
        if(user.userLevel != UserLevelBanned)
        {
            [self.menuOptions addObject:@(MenuOptionListen)];
            
            //if(user.userLevel == UserLevelBroadcaster || user.userLevel == UserLevelAdmin)
            //{
                [self.menuOptions addObject:@(MenuOptionBroadcast)];
            //}

            if(user.userLevel == UserLevelAdmin)
            {
                [self.menuOptions addObject:@(MenuOptionAdmin)];
            }
            
            [self.menuOptions addObject:@(MenuOptionProfile)];
        }
    }
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)screenName
{
    return @"Drawer";
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
    [self showAuthenticationWithCompletion:nil];
}

- (void)showAuthenticationWithCompletion:(void (^)())completion
{
    // Queue it at the end of the main run loop so it happens after the UI has been created.
    dispatch_async(dispatch_get_main_queue(), ^{
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.authNav = [storyboard instantiateViewControllerWithIdentifier:@"Authentication"];
        [self presentViewController:self.authNav animated:NO completion:completion];
    });
}

- (void)showPasswordReset
{
    if(self.authNav == nil)
    {
        [self showAuthenticationWithCompletion:^{
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            LRResetPasswordViewController* resetPassword = [storyboard instantiateViewControllerWithIdentifier:@"ResetPassword"];
            [self.authNav pushViewController:resetPassword animated:NO];
        }];
    }
    else
    {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        LRResetPasswordViewController* resetPassword = [storyboard instantiateViewControllerWithIdentifier:@"ResetPassword"];
        [self.authNav pushViewController:resetPassword animated:NO];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.menuOptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DrawerCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DrawerCell" forIndexPath:indexPath];
    
    cell.title.font = [UIFont fontWithName:@"Rokkitt" size:30.0];
    
    BOOL selected = NO;
    switch(((NSNumber*)self.menuOptions[indexPath.row]).integerValue)
    {
        case MenuOptionListen:
            if(self.mm_drawerController.centerViewController == self.listenMainViewController) selected = YES;
            cell.title.text = @"Listen";
            break;
            
        case MenuOptionBroadcast:
            if(self.mm_drawerController.centerViewController == self.broadcastRequestViewController) selected = YES;
            cell.title.text = @"Broadcast Request";
//            if(self.mm_drawerController.centerViewController == self.broadcastMainViewController) selected = YES;
//            cell.title.text = @"Broadcast";
            break;
            
        case MenuOptionAdmin:
            if(self.mm_drawerController.centerViewController == self.adminMainViewController) selected = YES;
            cell.title.text = @"Admin";
            break;
            
        case MenuOptionProfile:
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
    switch(((NSNumber*)self.menuOptions[indexPath.row]).integerValue)
    {
        case MenuOptionListen:
            centerViewController = self.listenMainViewController;
            break;
            
        case MenuOptionBroadcast:
            centerViewController = self.broadcastRequestViewController;
//            centerViewController = self.broadcastMainViewController;
            break;
            
        case MenuOptionAdmin:
            centerViewController = self.adminMainViewController;
            break;
            
        case MenuOptionProfile:
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
