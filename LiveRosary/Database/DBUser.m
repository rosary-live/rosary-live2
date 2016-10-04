//
//  DBUser.m
//  LiveRosary
//
//  Created by richardtaylor on 4/17/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "DBUser.h"

NSString* const kAllLevels = @"_ALL_";

@interface DBUser ()

@property (nonatomic, strong) NSMutableDictionary<NSString*, NSMutableArray*>* levels;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSDictionary*>* lastKey;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSNumber*>* complete;

@end

@implementation DBUser

+ (instancetype)sharedInstance
{
    static DBUser* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if(self != nil)
    {
        self.levels = [NSMutableDictionary new];
        self.lastKey = [NSMutableDictionary new];
        self.complete = [NSMutableDictionary new];
    }
    return self;
}

- (NSArray*)usersForLevel:(NSString*)level
{
    return self.levels[level ? level : kAllLevels];
}

- (BOOL)completeForLevel:(NSString*)level
{
    NSNumber* complete = self.complete[level ? level : kAllLevels];
    if(complete != nil)
    {
        return complete.boolValue;
    }
    
    return NO;
}

- (void)getUserByEmail:(NSString*)email completion:(void (^)(UserModel* user, NSError* error))completion
{
    CFTimeInterval startTime = CACurrentMediaTime();
    [[self.dynamoDBObjectMapper load:[UserModel class] hashKey:email rangeKey:nil] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        CFTimeInterval duration = CACurrentMediaTime() - startTime;
        
        if(task.error)
        {
            DDLogError(@"Load failed. Error: [%@]", task.error);
            [self logWithName:@"User byEmail Error" duration:duration count:0 error:task.error.description];
            safeBlock(completion, nil, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Load failed. Exception: [%@]", task.exception);
            [self logWithName:@"User byEmail Exception" duration:duration count:0 error:task.exception.description];
            safeBlock(completion, nil, [NSError errorWithDomain:ErrorDomainDatabase code:ErrorException userInfo:@{ NSLocalizedDescriptionKey: task.exception.description }]);
        }
        else if(task.result)
        {
            UserModel* user = task.result;
            //DDLogDebug(@"User: %@", user);
            [self logWithName:@"User byEmail" duration:duration count:1 error:nil];
            
            safeBlock(completion, user, nil);
        }
        
        return nil;
    }];
}

- (void)getUsersByEmail:(NSString*)email moreKey:(NSDictionary*)moreKey completion:(void (^)(NSArray<UserModel*>* users, NSDictionary* moreKey, NSError* error))completion
{
    AWSDynamoDBScanExpression* scanExpression = [AWSDynamoDBScanExpression new];
    //scanExpression.limit = @100;
    scanExpression.exclusiveStartKey = moreKey;
    scanExpression.filterExpression = @"contains(email, :val)";
    scanExpression.expressionAttributeValues = @{ @":val": email };
    
    CFTimeInterval startTime = CACurrentMediaTime();
    [[self.dynamoDBObjectMapper scan:[UserModel class] expression:scanExpression] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        CFTimeInterval duration = CACurrentMediaTime() - startTime;
        
        if(task.error)
        {
            DDLogError(@"Load failed. Error: [%@]", task.error);
            [self logWithName:@"Users byEmail Error" duration:duration count:0 error:task.error.description];
            safeBlock(completion, nil, nil, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Load failed. Exception: [%@]", task.exception);
            [self logWithName:@"Users byEmail Error" duration:duration count:0 error:task.exception.description];
            safeBlock(completion, nil, nil, [NSError errorWithDomain:ErrorDomainDatabase code:ErrorException userInfo:@{ NSLocalizedDescriptionKey: task.exception.description }]);
        }
        else if(task.result)
        {
            AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
//            for(UserModel* user in paginatedOutput.items)
//            {
//                DDLogDebug(@"User: %@", user);
//            }
            
            [self logWithName:@"User byEmail" duration:duration count:paginatedOutput.items.count error:nil];
                        
            safeBlock(completion, paginatedOutput.items, paginatedOutput.lastEvaluatedKey, nil);
        }
        
        return nil;
    }];
}

- (void)getUsersWithBroadcastRequest:(NSDictionary*)moreKey completion:(void (^)(NSArray<UserModel*>* users, NSDictionary* moreKey, NSError* error))completion {
    AWSDynamoDBScanExpression* scanExpression = [AWSDynamoDBScanExpression new];
    //scanExpression.limit = @100;
    scanExpression.exclusiveStartKey = moreKey;
    scanExpression.filterExpression = @"breq = :val";
    scanExpression.expressionAttributeValues = @{ @":val": @1 };
    
    CFTimeInterval startTime = CACurrentMediaTime();
    [[self.dynamoDBObjectMapper scan:[UserModel class] expression:scanExpression] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        CFTimeInterval duration = CACurrentMediaTime() - startTime;
        
        if(task.error)
        {
            DDLogError(@"Load failed. Error: [%@]", task.error);
            [self logWithName:@"Users byEmail Error" duration:duration count:0 error:task.error.description];
            safeBlock(completion, nil, nil, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Load failed. Exception: [%@]", task.exception);
            [self logWithName:@"Users byEmail Error" duration:duration count:0 error:task.exception.description];
            safeBlock(completion, nil, nil, [NSError errorWithDomain:ErrorDomainDatabase code:ErrorException userInfo:@{ NSLocalizedDescriptionKey: task.exception.description }]);
        }
        else if(task.result)
        {
            AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
//            for(UserModel* user in paginatedOutput.items)
//            {
//                DDLogDebug(@"User: %@", user);
//            }
            
            [self logWithName:@"User byEmail" duration:duration count:paginatedOutput.items.count error:nil];
            
            safeBlock(completion, paginatedOutput.items, paginatedOutput.lastEvaluatedKey, nil);
        }
        
        return nil;
    }];
}

- (void)getUsersByLevel:(NSString*)level reset:(BOOL)reset completion:(void (^)(NSArray<UserModel*>* allUsers, NSArray<UserModel*>* users, BOOL complete, NSError* error))completion
{
    if(reset)
    {
        [self.levels removeObjectForKey:level ? level : kAllLevels];
        [self.lastKey removeObjectForKey:level ? level : kAllLevels];
        [self.complete removeObjectForKey:level ? level : kAllLevels];
    }
    
    AWSDynamoDBScanExpression* scanExpression = [AWSDynamoDBScanExpression new];
    //scanExpression.limit = @100;
    if(level != nil)
    {
        scanExpression.exclusiveStartKey = self.lastKey[level ? level : kAllLevels];
        scanExpression.filterExpression = @"#atname = :val";
        scanExpression.expressionAttributeNames = @{ @"#atname": @"level" };
        scanExpression.expressionAttributeValues = @{ @":val": level };
    }
    
    if(level == nil) level = kAllLevels;
    
    if([self completeForLevel:level])
    {
        safeBlock(completion, self.levels[level], nil, YES, nil);
        return;
    }
    
    CFTimeInterval startTime = CACurrentMediaTime();
    [[self.dynamoDBObjectMapper scan:[UserModel class] expression:scanExpression] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        CFTimeInterval duration = CACurrentMediaTime() - startTime;
        
        if(task.error)
        {
            DDLogError(@"Load failed. Error: [%@]", task.error);
            [self logWithName:@"Users byLevel Error" duration:duration count:0 error:task.error.description];
            safeBlock(completion, nil, nil, NO, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Load failed. Exception: [%@]", task.exception);
            [self logWithName:@"Users byLevel Error" duration:duration count:0 error:task.exception.description];
            safeBlock(completion, nil, nil, NO, [NSError errorWithDomain:ErrorDomainDatabase code:ErrorException userInfo:@{ NSLocalizedDescriptionKey: task.exception.description }]);
        }
        else if(task.result)
        {
            AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
//            for(UserModel* user in paginatedOutput.items)
//            {
//                DDLogDebug(@"User: %@", user);
//            }
            
            [self logWithName:@"User byEmail" duration:duration count:paginatedOutput.items.count error:nil];
            
            NSMutableArray* users = self.levels[level];
            if(users == nil)
            {
                users = [NSMutableArray new];
                self.levels[level] = users;
            }
            
            [users addObjectsFromArray:paginatedOutput.items];
            
            NSDictionary* lastKey = paginatedOutput.lastEvaluatedKey;
            BOOL complete = lastKey == nil;
            if(complete)
            {
                [self.lastKey removeObjectForKey:level ? level : kAllLevels];
                self.complete[level] = @YES;
            }
            else
            {
                self.lastKey[level] = lastKey;
            }
            
            safeBlock(completion, users, paginatedOutput.items, complete, nil);
        }
        
        return nil;
    }];
}

- (void)getBroadcastRequestersWithCompletion:(void (^)(NSArray<UserModel*>* users, NSDictionary* moreKey, NSError* error))completion {
}

- (void)updateLevelForEmail:(NSString*)email from:(NSString*)fromLevel to:(NSString*)toLevel
{
    NSArray* allUsers = self.levels[kAllLevels];
    UserModel* user = [allUsers bk_match:^BOOL(id obj) {
        return [((UserModel*)obj).email isEqualToString:email];
    }];
    
    user.level = toLevel;
    
    NSMutableArray* fromUsers = self.levels[fromLevel];
    UserModel* fromUser = [fromUsers bk_match:^BOOL(id obj) {
        return [((UserModel*)obj).email isEqualToString:email];
    }];
    
    if(fromUser != nil)
    {
        [fromUsers removeObject:fromUser];
    }
    
    fromUser.level = toLevel;
    
    NSMutableArray* toUsers = self.levels[toLevel];
    UserModel* toUser = [toUsers bk_match:^BOOL(id obj) {
        return [((UserModel*)obj).email isEqualToString:email];
    }];
    
    if(toUser != nil)
    {
        toUser.level = toLevel;
    }
    else
    {
        if(user != nil || fromUser != nil)
        {
            [toUsers addObject:fromUser != nil ? fromUser : user];
        }
    }
}

@end
