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

@property (nonatomic, strong) NSMutableDictionary<NSString*,NSMutableArray*>* levels;
@property (nonatomic, strong) NSMutableDictionary<NSString*,NSDictionary*>* lastKey;

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
    }
    return self;
}

- (NSArray*)usersForLevel:(NSString*)level
{
    return self.levels[level];
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
            DDLogDebug(@"User: %@", user);
            [self logWithName:@"User byEmail" duration:duration count:1 error:nil];
            
            safeBlock(completion, user, nil);
        }
        
        return nil;
    }];
}

- (void)getUsersByLevel:(NSString*)level reset:(BOOL)reset completion:(void (^)(NSArray<UserModel*>* users, NSError* error))completion
{
    NSDictionary* exclusiveStartKey = self.lastKey[level ? level : kAllLevels];
    
    if(reset)
    {
        [self.levels removeObjectForKey:level ? level : kAllLevels];
        [self.lastKey removeObjectForKey:level ? level : kAllLevels];
    }
    
    AWSDynamoDBScanExpression* scanExpression = [AWSDynamoDBScanExpression new];
    //scanExpression.limit = @100;
    if(level != nil)
    {
        scanExpression.filterExpression = @"#atname = :val";
        scanExpression.expressionAttributeNames = @{ @"#atname": @"level" };
        scanExpression.expressionAttributeValues = @{ @":val": level };
    }
    
    if(level == nil) level = kAllLevels;
    
    CFTimeInterval startTime = CACurrentMediaTime();
    [[self.dynamoDBObjectMapper scan:[UserModel class] expression:scanExpression] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        CFTimeInterval duration = CACurrentMediaTime() - startTime;
        
        if(task.error)
        {
            DDLogError(@"Load failed. Error: [%@]", task.error);
            [self logWithName:@"Users byLevel Error" duration:duration count:0 error:task.error.description];
            safeBlock(completion, nil, task.error);
        }
        else if(task.exception)
        {
            DDLogError(@"Load failed. Exception: [%@]", task.exception);
            [self logWithName:@"Users byLevel Error" duration:duration count:0 error:task.exception.description];
            safeBlock(completion, nil, [NSError errorWithDomain:ErrorDomainDatabase code:ErrorException userInfo:@{ NSLocalizedDescriptionKey: task.exception.description }]);
        }
        else if(task.result)
        {
            AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
            for(UserModel* user in paginatedOutput.items)
            {
                DDLogDebug(@"User: %@", user);
            }
            
            [self logWithName:@"User byEmail" duration:duration count:paginatedOutput.items.count error:nil];
            
            NSMutableArray* users = self.levels[level];
            if(users == nil)
            {
                users = [NSMutableArray new];
                self.levels[level] = users;
            }
            
            [users addObjectsFromArray:paginatedOutput.items];
            
            safeBlock(completion, paginatedOutput.items, nil);
        }
        
        return nil;
    }];
}

@end
