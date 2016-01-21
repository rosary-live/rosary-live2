//
//  LiveRosaryAuthenticationClient.m
//  LiveRosary
//
//  Created by richardtaylor on 1/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "LiveRosaryAuthenticationClient.h"
#import <AWSCore/AWSCore.h>
#import <AWSLambda/AWSLambda.h>
#import <UICKeyChainStore/UICKeyChainStore.h>

NSString *const LiveRosaryAuthenticationClientDomain = @"LiveRosaryAuthenticationClientDomain";

//NSString *const ProviderPlaceHolder = @"foobar.com";
//NSString *const LoginURI = @"%@/login?&username=%@&timestamp=%@&signature=%@";
//NSString *const GetTokenURI = @"%@/gettoken?uid=%@&timestamp=%@%@&signature=%@";
//NSString *const DeveloperAuthenticationClientDomain = @"com.amazonaws.service.cognitoidentity.DeveloperAuthenticatedIdentityProvider";
//NSString *const UidKey = @"uid";
//NSString *const EncryptionKeyKey = @"authkey";

//NSString * const KeyIdentityPooelId = @"KeyIdentityPoolId";
NSString * const KeyEmail = @"KeyEmail";
NSString * const KeyPassword = @"KeyPassword";
NSString * const KeyIdentityId = @"KeyIdentityId";
NSString * const KeyToken = @"KeyToken";

@interface LiveRosaryAuthenticationResponse()

@property (nonatomic, strong) NSString* identityId;
//@property (nonatomic, strong) NSString* identityPoolId;
@property (nonatomic, strong) NSString* token;

@end

@implementation LiveRosaryAuthenticationResponse
@end

@interface LiveRosaryAuthenticationClient()
//@property (nonatomic, strong) NSString* identityPoolId;
@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* password;
@property (nonatomic, strong) NSString* identityId;
@property (nonatomic, strong) NSString* token;

//// used for internal encryption
//@property (nonatomic, strong) NSString* uid;
//@property (nonatomic, strong) NSString* key;

// used to save state of authentication
@property (nonatomic, strong) UICKeyChainStore* keychain;

@end

@implementation LiveRosaryAuthenticationClient


+ (instancetype)identityProviderWithAppname:(NSString *)appname {// endpoint:(NSString *)endpoint {
    return [[LiveRosaryAuthenticationClient alloc] initWithAppname:appname];// endpoint:endpoint];
}

- (instancetype)initWithAppname:(NSString *)appname {// endpoint:(NSString *)endpoint {
    if (self = [super init]) {
        self.appname  = appname;
        //self.endpoint = endpoint;
        
        self.keychain = _keychain = [UICKeyChainStore keyChainStoreWithService:[NSString stringWithFormat:@"%@.%@.%@", [NSBundle mainBundle].bundleIdentifier, [LiveRosaryAuthenticationClient class], self.appname]];
        
        self.email = self.keychain[KeyEmail];
        self.password = self.keychain[KeyPassword];
        self.identityId = self.keychain[KeyIdentityId];
        self.token = self.keychain[KeyToken];
        
        //self.uid = self.keychain[UidKey];
        //self.key = self.keychain[EncryptionKeyKey];
    }
    
    return self;
}

- (BOOL)isAuthenticated {
    return self.identityId != nil;
}

// login and get a decryption key to be used for subsequent calls
- (AWSTask *)login:(NSString*)email password:(NSString*)password {
    
    // If the key is already set, the login already succeeeded
    if (self.identityId) {
        return [AWSTask taskWithResult:self.identityId];
    }
    
    AWSLambdaInvoker* lambdaInvoker = [AWSLambdaInvoker defaultLambdaInvoker];
    return [[lambdaInvoker invokeFunction:@"LambdAuthLogin" JSONObject:@{ @"email": email, @"password": password }] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        
        LiveRosaryAuthenticationResponse* authResponse;
        
        if(task.error)
        {
            DDLogError(@"login error %@", task.error);
            return [AWSTask taskWithError:[NSError errorWithDomain:LiveRosaryAuthenticationClientDomain
                                                              code:LiveRosaryAuthenticationClientLoginError
                                                          userInfo:nil]];
        }
        else if(task.exception)
        {
            DDLogError(@"login exception: %@", task.exception);
            return [AWSTask taskWithError:[NSError errorWithDomain:LiveRosaryAuthenticationClientDomain
                                                              code:LiveRosaryAuthenticationClientLoginError
                                                          userInfo:nil]];
        }
        else if(task.result) {
            DDLogDebug(@"login result: %@", task.result);
            
//            self.email = email;
//            self.password = password;
            
            if([(NSNumber*)task.result[@"login"] boolValue])
            {
                self.keychain[KeyEmail] = self.email = email;
                self.keychain[KeyPassword] = self.password = password;
                self.keychain[KeyIdentityId] = self.identityId = task.result[@"identityId"];
                self.keychain[KeyToken] = self.token = task.result[@"token"];
            }
            
            authResponse = [LiveRosaryAuthenticationResponse new];
            authResponse.identityId = self.identityId;
            authResponse.token = self.token;
        }
        
        return [AWSTask taskWithResult:authResponse];
    }];
    
//    if (self.uid == nil) {
//        // generate a session id for communicating with backend
//        self.uid = [Crypto generateRandomString];
//    }
//    
//    return [[AWSTask taskWithResult:nil] continueWithBlock:^id(AWSTask *task) {
//        NSURL *request = [NSURL URLWithString:[self buildLoginRequestUrl:username password:password]];
//        NSData *rawResponse = [NSData dataWithContentsOfURL:request];
//        if (!rawResponse) {
//            return [AWSTask taskWithError:[NSError errorWithDomain:LiveRosaryAuthenticationClientDomain
//                                                              code:LiveRosaryAuthenticationClientLoginError
//                                                          userInfo:nil]];
//        }
//        
//        NSString *response = [[NSString alloc] initWithData:rawResponse encoding:NSUTF8StringEncoding];
//        AWSLogDebug(@"response: %@", response);
//        NSString *key = [[self computeDecryptionKey:username password:password] substringToIndex:32];
//        NSData *body = [Crypto decrypt:response key:key];
//        if (!body) {
//            return [AWSTask taskWithError:[NSError errorWithDomain:LiveRosaryAuthenticationClientDomain
//                                                              code:LiveRosaryAuthenticationClientDecryptError
//                                                          userInfo:nil]];
//        }
//        
//        NSString *json = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
//        NSLog(@"json: %@", json);
//        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:body options:kNilOptions error:nil];
//        self.key = [jsonDict objectForKey:@"key"];
//        if (!self.key) {
//            return [AWSTask taskWithError:[NSError errorWithDomain:LiveRosaryAuthenticationClientDomain
//                                                              code:LiveRosaryAuthenticationClientUnknownError
//                                                          userInfo:nil]];
//        }
//        AWSLogDebug(@"key: %@", self.key);
//        
//        // Save our key/uid to the keychain
//        self.keychain[UidKey] = self.uid;
//        self.keychain[EncryptionKeyKey] = self.key;
//        
//        return [AWSTask taskWithResult:nil];
//    }];
    
}

- (void)logout {
//    self.key = nil;
//    self.keychain[EncryptionKeyKey] = nil;
//    self.uid = nil;
//    self.keychain[UidKey] = nil;
}

// call gettoken and set our values from returned result
- (AWSTask *)getToken:(NSString *)identityId logins:(NSDictionary *)logins {
    
    // make sure we've authenticated
    if (![self isAuthenticated]) {
        return [AWSTask taskWithError:[NSError errorWithDomain:LiveRosaryAuthenticationClientDomain
                                                          code:LiveRosaryAuthenticationClientLoginError
                                                      userInfo:nil]];
    }
    
    return [self login:self.email password:self.password];
    
//    return [[AWSTask taskWithResult:nil] continueWithBlock:^id(AWSTask *task) {
//        NSURL *request = [NSURL URLWithString:[self buildGetTokenRequestUrl:identityId logins:logins]];
//        NSData *rawResponse = [NSData dataWithContentsOfURL:request];
//        if (!rawResponse) {
//            return [AWSTask taskWithError:[NSError errorWithDomain:LiveRosaryAuthenticationClientDomain
//                                                              code:LiveRosaryAuthenticationClientLoginError
//                                                          userInfo:nil]];
//        }
//        
//        NSString *response = [[NSString alloc] initWithData:rawResponse encoding:NSUTF8StringEncoding];
//        NSData *body = [Crypto decrypt:response key:self.key];
//        if (!body) {
//            return [AWSTask taskWithError:[NSError errorWithDomain:LiveRosaryAuthenticationClientDomain
//                                                              code:LiveRosaryAuthenticationClientDecryptError
//                                                          userInfo:nil]];
//        }
//        
//        NSString *json = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
//        NSLog(@"json: %@", json);
//        
//        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:body options:kNilOptions error:nil];
//        
//        LiveRosaryAuthenticationResponse *authResponse = [LiveRosaryAuthenticationResponse new];
//        
//        authResponse.token = [jsonDict objectForKey:@"token"];
//        authResponse.identityId = [jsonDict objectForKey:@"identityId"];
//        authResponse.identityPoolId = [jsonDict objectForKey:@"identityPoolId"];
//        if (!(authResponse.token || authResponse.identityId || authResponse.identityPoolId)) {
//            return [AWSTask taskWithError:[NSError errorWithDomain:LiveRosaryAuthenticationClientDomain
//                                                              code:LiveRosaryAuthenticationClientUnknownError
//                                                          userInfo:nil]];
//        }
//        
//        return [AWSTask taskWithResult:authResponse];
//    }];
}

//- (NSString *)buildLoginRequestUrl:(NSString *)username password:(NSString *)password {
//    
//    NSDate   *currentTime = [NSDate date];
//    NSString *timestamp = [currentTime aws_stringValue:AWSDateISO8601DateFormat1];
//    NSData   *signature = [Crypto sha256HMac:[timestamp dataUsingEncoding:NSASCIIStringEncoding] withKey:[self computeDecryptionKey:username password:password]];
//    NSString *rawSig    = [[NSString alloc] initWithData:signature encoding:NSASCIIStringEncoding];
//    NSString *hexSign   = [Crypto hexEncode:rawSig];
//    
//    return [NSString stringWithFormat:LoginURI, self.endpoint, self.uid, username, timestamp, hexSign];
//}

//- (NSString *)buildGetTokenRequestUrl:(NSString *)identityId logins:(NSDictionary *)logins {
//    NSDate   *currentTime = [NSDate date];
//    NSString *timestamp = [currentTime aws_stringValue:AWSDateISO8601DateFormat1];
//    NSMutableString *stringToSign = [NSMutableString stringWithString:timestamp];
//    NSMutableString *providerParams = [NSMutableString stringWithString:@""];
//    int loginCount = 1;
//    for (NSString *provider in [logins allKeys]) {
//        [stringToSign appendFormat:@"%@%@", provider, [logins objectForKey:provider]];
//        [providerParams appendFormat:@"&provider%d=%@&token%d=%@",loginCount,provider,loginCount, [logins objectForKey:provider]];
//        loginCount++;
//    }
//    if (identityId) {
//        [stringToSign appendString:identityId];
//        [providerParams appendFormat:@"&identityId=%@", [identityId aws_stringWithURLEncoding]];
//    }
//    NSData   *signature = [Crypto sha256HMac:[stringToSign dataUsingEncoding:NSUTF8StringEncoding] withKey:self.key];
//    NSString *rawSig    = [[NSString alloc] initWithData:signature encoding:NSASCIIStringEncoding];
//    NSString *hexSign   = [Crypto hexEncode:rawSig];
//    
//    return [NSString stringWithFormat:GetTokenURI, self.endpoint, self.uid, timestamp, providerParams, hexSign];
//}

//- (NSString *)computeDecryptionKey:(NSString *)username password:(NSString *)password {
//    NSURL *URL = [NSURL URLWithString:self.endpoint];
//    NSString *hostname = URL.host;
//    
//    
//    NSString *salt       = [NSString stringWithFormat:@"%@%@%@", username, self.appname, hostname];
//    NSData   *hashedSalt = [Crypto sha256HMac:[salt dataUsingEncoding:NSUTF8StringEncoding] withKey:password];
//    NSString *rawSaltStr = [[NSString alloc] initWithData:hashedSalt encoding:NSASCIIStringEncoding];
//    
//    return [Crypto hexEncode:rawSaltStr];
//}

@end
