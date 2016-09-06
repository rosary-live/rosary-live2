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
#import "BroadcastRequestUserCell.h"

typedef NS_ENUM(NSUInteger, Level) {
    LevelAll,
    LevelAdmin,
    LevelBroadcast,
    LevelListen,
    LevelBanned
};

typedef NS_ENUM(NSUInteger, Section) {
    SectionBroadcastRequests,
    SectionAll,
};

@interface LRAdminManageUsersViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar* searchBar;
@property (nonatomic, weak) IBOutlet UISegmentedControl* filter;
@property (nonatomic, weak) IBOutlet UITableView* tableView;

@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonnull, readonly) NSString* currentLevel;
@property (nonnull, strong) NSArray* users;
@property (nonatomic, strong) NSArray<UserModel *>* usersWithBroadcastRequest;

@property (nonatomic, strong) NSArray* searchResults;
@property (nonatomic, strong) NSDictionary* searchMoreKey;

@end

@implementation LRAdminManageUsersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchBar.delegate = self;
    [self onFilterChanged:nil];
    
    [self updateUsersWithBroadcastRequest];
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
        case LevelBroadcast: return @"broadcast";
        case LevelListen: return @"listener";
        case LevelBanned: return @"banned";
        default: return nil;
    }
}

- (NSString*)currentFilterName {
    switch(self.filter.selectedSegmentIndex) {
        case LevelAll: return @"All Users";
        case LevelAdmin: return @"Admin Users";
        case LevelBroadcast: return @"Broadcaster Users";
        case LevelListen: return @"Listener Users";
        case LevelBanned: return @"Banned Users";
    }
    
    return @"";
}

- (void)updateUsersWithBroadcastRequest {
    [[DBUser sharedInstance] getUsersWithBroadcastRequest:nil completion:^(NSArray<UserModel *> *users, NSDictionary *moreKey, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.usersWithBroadcastRequest = users;
            [self.tableView reloadData];
        });
    }];
}

- (IBAction)onFilterChanged:(id)sender
{
    self.users = [[DBUser sharedInstance] usersForLevel:self.currentLevel];
    if(self.users.count == 0 && ![[DBUser sharedInstance] completeForLevel:self.currentLevel])
    {
        [[AnalyticsManager sharedManager] event:@"Adming Manage Users Filter" info:@{ @"filter": self.currentLevel ? self.currentLevel : @"All" }];
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case SectionBroadcastRequests:
            return self.usersWithBroadcastRequest.count;
            
        case SectionAll:
            return self.searchResults.count > 0 ? self.searchResults.count + 1 : self.users.count;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.0f;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView* header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
    header.backgroundColor = [UIColor colorFromHexString:@"#e0e0dc"];
    UILabel* headerText = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, tableView.frame.size.width - 16, 30)];
    headerText.font = [UIFont fontWithName:@"Veranda" size:22.0f];
    
    switch(section) {
        case SectionBroadcastRequests:
            headerText.text = @"Broadcast Requests";
            break;
            
        case SectionAll:
            headerText.text = self.searchResults.count > 0 ? @"Search Results" : [self currentFilterName];
            break;
    }
    
    [header addSubview:headerText];
    
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == SectionAll) {
        if(self.searchResults.count > 0 && indexPath.row >= self.searchResults.count)
        {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCompleteCell" forIndexPath:indexPath];
            return cell;
        }
        else
        {
            UserCell* cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
            UserModel* user = self.searchResults.count > 0 ? self.searchResults[indexPath.row] : self.users[indexPath.row];
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
    } else {
        BroadcastRequestUserCell* cell = [tableView dequeueReusableCellWithIdentifier:@"BroadcastRequestUserCell" forIndexPath:indexPath];
        UserModel* user = self.searchResults.count > 0 ? self.searchResults[indexPath.row] : self.users[indexPath.row];
        cell.email.text = user.email;
        cell.name.text = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
        cell.location.text = [NSString stringWithFormat:@"%@, %@", user.city, user.state];
        cell.language.text = user.language;
        cell.level.text = user.level;
        cell.countryFlag.image = [[UserManager sharedManager] imageForCountryName:user.country];
        
        NSString* urlString = [NSString stringWithFormat:@"https://s3.amazonaws.com/liverosaryavatars/%@", [user.email stringByReplacingOccurrencesOfString:@"@" withString:@"-"]];
        [cell.avatar sd_setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:[UIImage imageNamed:@"AvatarImage"] options:0];
        
        cell.requestText.text = user.reqtext;
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.section) {
        case SectionAll:
            return 70.0f;
            
        case SectionBroadcastRequests:
            return 133.0f;
   }
    
    return 0.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == SectionAll) {
        if(self.searchResults.count > 0 && indexPath.row >= self.searchResults.count)
        {
            self.searchBar.text = @"";
            self.searchResults = nil;
            [tableView reloadData];
        }
    }
}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* actions = [NSMutableArray new];
    UserModel* user = self.searchResults.count > 0 ? self.searchResults[indexPath.row] : self.users[indexPath.row];
    
//    if(![user.level isEqualToString:@"admin"])
//    {
//        UITableViewRowAction* adminAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Admin" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
//
//            [self updateUser:user toLevel:@"admin"];
//        }];
//        
//        adminAction.backgroundColor = [UIColor orangeColor];
//        [actions addObject:adminAction];
//    }
    
    if(indexPath.section == SectionAll) {
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
    } else {
        UITableViewRowAction* approveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Approve" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {

            self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.hud.labelText = @"Updating User";
            
            [[LiveRosaryService sharedService] updateUserForBroadcastRequest:user.email approve:YES adminEmail:[UserManager sharedManager].email adminPassword:[UserManager sharedManager].password completion:^(NSError *error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.hud hide:YES];
                    [self.tableView reloadData];
                    
                    [self updateUsersWithBroadcastRequest];
                });
            }];
        }];
        
        approveAction.backgroundColor = [UIColor greenColor];
        [actions addObject:approveAction];
        
        UITableViewRowAction* denyAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Deny" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            
            self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.hud.labelText = @"Updating User";
            
            [[LiveRosaryService sharedService] updateUserForBroadcastRequest:user.email approve:NO adminEmail:[UserManager sharedManager].email adminPassword:[UserManager sharedManager].password completion:^(NSError *error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.hud hide:YES];
                    [self.tableView reloadData];
                    
                    [self updateUsersWithBroadcastRequest];
                });
            }];
        }];
        
        denyAction.backgroundColor = [UIColor redColor];
        [actions addObject:denyAction];
        
    }
    
    return actions;
}

//- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return NO;
//}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];

    if(self.searchBar.text.length > 3)
    {
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.labelText = @"Searching";
        
        [[DBUser sharedInstance] getUsersByEmail:self.searchBar.text.lowercaseString moreKey:nil completion:^(NSArray<UserModel *> *users, NSDictionary *moreKey, NSError *error) {
            self.searchResults = users;
            
            [[AnalyticsManager sharedManager] event:@"Manage Users Search" info:@{ @"text": self.searchBar.text, @"count": @(users.count) }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.hud hide:YES];
                
                if(self.searchResults.count > 0)
                {
                    self.searchMoreKey = moreKey;
                    [self.tableView reloadData];
                }
                else
                {
                    [UIAlertView bk_showAlertViewWithTitle:nil message:@"No users found." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
                }
            });
        }];
    }
    else
    {
        [UIAlertView bk_showAlertViewWithTitle:nil message:@"You must enter at least 4 characters." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [[AnalyticsManager sharedManager] event:@"Manage Users Search Cancel" info:nil];
    
    [self.searchBar resignFirstResponder];
    self.searchBar.text = @"";
    self.searchResults = nil;
    [self.tableView reloadData];
}

- (void)updateUser:(UserModel*)user toLevel:(NSString*)level
{
    DDLogDebug(@"User -> %@ %@", user.email, level);
    
    [[AnalyticsManager sharedManager] event:@"Manage Users Update" info:@{ @"tolevel": level }];
    
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
