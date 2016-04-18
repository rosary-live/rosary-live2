//
//  LRAdminManageUsersViewController.m
//  LiveRosary
//
//  Created by Richard Taylor on 4/15/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRAdminManageUsersViewController.h"
#import "UserManager.h"
#import "DBUser.h"
#import "UserCell.h"
#import "LiveRosaryService.h"
#import "UserManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <MBProgressHUD/MBProgressHUD.h>

typedef NS_ENUM(NSUInteger, Level) {
    LevelAll,
    LevelAdmin,
    LevelBroadcast,
    LevelListen,
    LevelBanned
};

@interface LRAdminManageUsersViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UISearchBar* searchBar;
@property (nonatomic, weak) IBOutlet UISegmentedControl* filter;
@property (nonatomic, weak) IBOutlet UITableView* tableView;

@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonnull, readonly) NSString* currentLevel;
@property (nonnull, strong) NSArray* users;

@end

@implementation LRAdminManageUsersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self onFilterChanged:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)screenName
{
    return @"Admin Manage Users";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSString*)currentLevel
{
    switch(self.filter.selectedSegmentIndex)
    {
        case LevelAdmin: return @"admin";
        case LevelBroadcast: return @"broadcaster";
        case LevelListen: return @"listener";
        case LevelBanned: return @"banned";
        default: return nil;
    }
}

- (IBAction)onFilterChanged:(id)sender
{
    self.users = [[DBUser sharedInstance] usersForLevel:self.currentLevel];
    if(self.users.count == 0 && ![[DBUser sharedInstance] completeForLevel:self.currentLevel])
    {
        [[DBUser sharedInstance] getUsersByLevel:self.currentLevel reset:NO completion:^(NSArray<UserModel *> *allUsers, NSArray<UserModel *> *users, BOOL complete, NSError *error) {
            self.users = allUsers;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
    }
    else
    {
        [self.tableView reloadData];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserCell* cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
    UserModel* user = self.users[indexPath.row];
    cell.email.text = user.email;
    cell.name.text = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
    cell.location.text = [NSString stringWithFormat:@"%@, %@", user.city, user.state];
    cell.language.text = user.language;
    cell.level.text = user.level;
    cell.countryFlag.image = [[UserManager sharedManager] imageForCountryName:user.country];

    NSString* urlString = [NSString stringWithFormat:@"https://s3.amazonaws.com/liverosaryavatars/%@", [user.email stringByReplacingOccurrencesOfString:@"@" withString:@"-"]];
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
}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* actions = [NSMutableArray new];
    UserModel* user = self.users[indexPath.row];
    
    if(![user.level isEqualToString:@"admin"])
    {
        UITableViewRowAction* adminAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Admin" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {

            [self updateUser:user toLevel:@"admin"];
        }];
        
        adminAction.backgroundColor = [UIColor orangeColor];
        [actions addObject:adminAction];
    }
    
    if(![user.level isEqualToString:@"broadcaster"])
    {
        UITableViewRowAction* broadcastAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Broadcast" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            
            [self updateUser:user toLevel:@"broadcaster"];
        }];
        
        broadcastAction.backgroundColor = [UIColor blueColor];
        [actions addObject:broadcastAction];
    }
    
    if(![user.level isEqualToString:@"listener"])
    {
        UITableViewRowAction* listenAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Listen" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            
            [self updateUser:user toLevel:@"listener"];
        }];
        
        listenAction.backgroundColor = [UIColor greenColor];
        [actions addObject:listenAction];
    }
    
    if(![user.level isEqualToString:@"banned"])
    {
        UITableViewRowAction* banAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Ban" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {

            [self updateUser:user toLevel:@"banned"];
        }];
        
        banAction.backgroundColor = [UIColor redColor];
        [actions addObject:banAction];
    }
    
    return actions;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)updateUser:(UserModel*)user toLevel:(NSString*)level
{
    DDLogDebug(@"User -> %@ %@", user.email, level);
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = @"Updating User";
    [[LiveRosaryService sharedService] updateUserWithEmail:user.email toLevel:level adminEmail:[UserManager sharedManager].email adminPassword:[UserManager sharedManager].password completion:^(NSError *error) {
        
        if(error == nil)
        {
            [[DBUser sharedInstance] updateLevelForEmail:user.email from:user.level to:level];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.hud hide:YES];
            [self.tableView reloadData];
        });
    }];
}

@end
