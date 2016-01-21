//
//  LiveRosaryAuthenticatedIdentityProvider.h
//  LiveRosary
//
//  Created by richardtaylor on 1/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import <AWSCognito/AWSCognito.h>

@class LiveRosaryAuthenticationClient;

@interface LiveRosaryAuthenticatedIdentityProvider : AWSAbstractCognitoIdentityProvider

@property (strong, atomic, readonly) LiveRosaryAuthenticationClient* client;

- (instancetype)initWithRegionType:(AWSRegionType)regionType
                        identityId:(NSString*)identityId
                    identityPoolId:(NSString*)identityPoolId
                            logins:(NSDictionary*)logins
                      providerName:(NSString*)providerName
                        authClient:(LiveRosaryAuthenticationClient*)client;

@end
