//
//  LRReportBroadcastViewController.m
//  LiveRosary
//
//  Created by Richard Taylor on 3/29/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LRReportBroadcastViewController.h"
#import "UserManager.h"
#import "BranchUniversalObject.h"
#import "BranchLinkProperties.h"
#import "LiveRosaryService.h"

@interface LRReportBroadcastViewController ()

@property (nonatomic, weak) IBOutlet UIButton* report;
@property (nonatomic, weak) IBOutlet UITextView* reason;

@end

@implementation LRReportBroadcastViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (IBAction)onReport:(id)sender
{
    if(self.reason.text.length == 0)
    {
        [UIAlertView bk_showAlertViewWithTitle:@"Error" message:@"You must enter a reason." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
        return;
    }
    
    BranchUniversalObject *branchUniversalObject = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:[NSString stringWithFormat:@"%@/%@", self.broadcast.bid, [UserManager sharedManager].email]];
    branchUniversalObject.title = @"Report Broadcast";
    branchUniversalObject.contentDescription = [NSString stringWithFormat:@"Report Broadcast by %@ for %@", [UserManager sharedManager].email, self.broadcast.user];
    //branchUniversalObject.imageUrl = @"https://example.com/mycontent-12345.png";
    [branchUniversalObject addMetadataKey:@"reporter" value:[UserManager sharedManager].email];
    [branchUniversalObject addMetadataKey:@"reportee" value:self.broadcast.user];
    [branchUniversalObject addMetadataKey:@"broadcast" value:self.broadcast.bid];
    
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    
    [branchUniversalObject getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString *url, NSError *error) {
        if(error != nil)
        {
            DDLogError(@"Error getting branch.io report link: %@", error);
        }
        else
        {
            NSLog(@"success getting url! %@", url);
        }
        
        NSString* name = [NSString stringWithFormat:@"%@ %@", [UserManager sharedManager].currentUser.firstName, [UserManager sharedManager].currentUser.lastName];
        [[LiveRosaryService sharedService] reportBroadcast:self.broadcast reporterName:name reporterEmail:[UserManager sharedManager].email reason:self.reason.text link:url completion:^(NSError *error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if(error != nil)
                {
                    [UIAlertView bk_showAlertViewWithTitle:@"Error" message:@"Unable to report broadcast." cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:nil];
                }
                else
                {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            });
        }];
    }];
}

@end
