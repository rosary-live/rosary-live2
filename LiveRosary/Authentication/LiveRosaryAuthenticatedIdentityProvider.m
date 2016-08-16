//
//  LiveRosaryAuthenticatedIdentityProvider.m
//  LiveRosary
//
//  Created by richardtaylor on 1/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LiveRosaryAuthenticatedIdentityProvider.h"

#import <AWSCore/AWSCore.h>
#import "LiveRosaryAuthenticatedIdentityProvider.h"
#import "LiveRosaryAuthenticationClient.h"

@interface LiveRosaryAuthenticatedIdentityProvider()
@property (strong, atomic) LiveRosaryAuthenticationClient *client;
@property (strong, atomic) NSString* providerName;
@property (strong, atomic) NSString* token;
@end

@implementation LiveRosaryAuthenticatedIdentityProvider

@synthesize providerName=_providerName;
@synthesize token=_token;

- (instancetype)initWithRegionType:(AWSRegionType)regionType
                        identityId:(NSString *)identityId
                    identityPoolId:(NSString *)identityPoolId
                            logins:(NSDictionary *)logins
                      providerName:(NSString *)pName
                        authClient:(LiveRosaryAuthenticationClient *)client {
    if (self = [super initWithRegionType:regionType identityId:identityId accountId:nil identityPoolId:identityPoolId logins:logins]) {
        self.client = client;
        self.providerName = pName;
    }
    return self;
}

- (AWSTask *)getIdentityId
{
    if(self.identityId != nil)
    {
        return [AWSTask taskWithResult:self.identityId];
    }
    else
    {
        return [self refresh];
    }
}

- (AWSTask *)refresh
{
    return [[self.client getToken] continueWithSuccessBlock:^id(AWSTask *task) {
        if(task.error != nil)
        {
            return task;
        }
        else
        {
            LiveRosaryAuthenticationResponse* response = task.result;
            self.identityId = response.identityId;
            self.token = response.token;
            self.user = response.user;
            return [AWSTask taskWithResult:self.identityId];
        }
    }];
}

@end
