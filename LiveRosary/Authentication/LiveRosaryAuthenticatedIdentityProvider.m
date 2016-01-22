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

@synthesize providerName = _providerName;
@synthesize token;

- (instancetype)initWithRegionType:(AWSRegionType)regionType
                        identityId:(NSString *)identityId
                    identityPoolId:(NSString *)identityPoolId
                            logins:(NSDictionary *)logins
                      providerName:(NSString *)providerName
                        authClient:(LiveRosaryAuthenticationClient *)client {
    if (self = [super initWithRegionType:regionType identityId:identityId accountId:nil identityPoolId:identityPoolId logins:logins]) {
        self.client = client;
        self.providerName = providerName;
    }
    return self;
}

//- (BOOL)authenticatedWithProvider {
//    return [self.logins objectForKey:self.providerName] != nil;
//}


- (AWSTask *)getIdentityId {
    // already cached the identity id, return it
    if (NO) {//self.identityId) {
        return [AWSTask taskWithResult:nil];
    }
//    // not authenticated with our developer provider
//    else if (![self authenticatedWithProvider]) {
//        return [super getIdentityId];
//    }
    // authenticated with our developer provider, use refresh logic to get id/token pair
    else {
        return [[AWSTask taskWithResult:nil] continueWithBlock:^id(AWSTask *task) {
            //if (!self.identityId) {
                return [self refresh];
            //}
            return [AWSTask taskWithResult:self.identityId];
        }];
    }
}

- (AWSTask *)refresh {
//    if (![self authenticatedWithProvider]) {
//        // We're using the simplified flow, so just return identity id
//        return [super getIdentityId];
//    }
//    else {
        return [[self.client getToken:self.identityId logins:self.logins] continueWithSuccessBlock:^id(AWSTask *task) {
            if (task.result) {
                LiveRosaryAuthenticationResponse *response = task.result;
//                if (![self.identityPoolId isEqualToString:response.identityPoolId]) {
//                    return [AWSTask taskWithError:[NSError errorWithDomain:LiveRosaryAuthenticationClientDomain
//                                                                      code:LiveRosaryAuthenticationClientInvalidConfig
//                                                                  userInfo:nil]];
//                }
                
                // potential for identity change here
                self.identityId = response.identityId;
                self.token = response.token;
            }
            return [AWSTask taskWithResult:self.identityId];
        }];
//    }
}

@end
