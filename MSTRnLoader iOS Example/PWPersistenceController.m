//
//  PWPersistenceController.m
//  Warehouse
//
//  Created by Fan Li Lin on 2018/11/13.
//  Copyright © 2018 FLL. All rights reserved.
//

#import "PWPersistenceController.h"

#if __has_include(<CocoaLumberjack/CocoaLumberjack.h>)
#define MCLogError(fmt, ...) DDLogError((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define MCLogVerbose(fmt, ...) DDLogVerbose((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define MCLogError(...) NSLog(__VA_ARGS__)
#define MCLogVerbose(...) NSLog(__VA_ARGS__)
#endif

@interface PWPersistenceController ()
@property (strong, nonatomic) NSManagedObjectContext *persistingMoc;
@property (strong, nonatomic) NSManagedObjectContext *mainMoc;
@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;
@end

@implementation PWPersistenceController

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - init method

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
        NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
        
        self.persistingMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        self.persistingMoc.persistentStoreCoordinator = psc;
        
        self.mainMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        self.mainMoc.parentContext = self.persistingMoc;
        
        NSString *queueName = [NSString stringWithFormat:@"com.mst.coredata.flow.queue-%@", [[NSUUID UUID] UUIDString]];
        self.synchronizationQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
        options[NSMigratePersistentStoresAutomaticallyOption] = @YES;
        options[NSInferMappingModelAutomaticallyOption] = @YES;
        
        NSURL *localStoreURL = [[[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"Mars.sqlite"];
        NSError *error = nil;
        
        NSPersistentStore *store = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:localStoreURL options:options error:&error];
        
        if (!store) {
            MCLogError(@"!!! Error: adding local persistent store to coordinator !!!\n%@\n", [error localizedDescription]);
        }
    }
    return self;
}

#pragma mark - public method

- (NSArray *)findObjectWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate sortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors
{
    __block NSArray *objects;
    [self.mainMoc performBlockAndWait:^{
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:name];
        request.predicate = predicate;
        request.sortDescriptors = sortDescriptors;
        NSError *error = nil;
        objects = [self.mainMoc executeFetchRequest:request error:&error];
        if (error) {
            MCLogError(@"!!! Error: find objects in main context !!!\n%@\n", [error localizedDescription]);
        }
    }];
    return objects;
}

- (NSManagedObject *)findObjectById:(NSManagedObjectID *)objectId
{
    return [self.mainMoc objectWithID:objectId];
}

- (NSUInteger)countObjectWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate
{
    __block NSUInteger count;
    [self.mainMoc performBlockAndWait:^{
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:name];
        request.predicate = predicate;
        NSError *error = nil;
        count = [self.mainMoc countForFetchRequest:request error:&error];
        if (error) {
            MCLogError(@"!!! Error: count objects in main context !!!\n%@\n", [error localizedDescription]);
        }
    }];
    return count;
}

- (NSManagedObject *)createObjectWithEntityName:(NSString *)name
{
    __block NSManagedObject *object = nil;
    
    [self.mainMoc performBlockAndWait:^{
        object = (NSManagedObject *)[NSEntityDescription insertNewObjectForEntityForName:name inManagedObjectContext:self.mainMoc];
    }];
    return object;
}

- (NSManagedObject *)createObjectWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate
{
    NSManagedObject *object = [self objectWithEntityName:name predicate:predicate];
    
    if (!object) {
        object = [self createObjectWithEntityName:name];
    }
    return object;
}

- (NSManagedObject *)objectWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate
{
    __block NSManagedObject *object = nil;
    
    MCLogVerbose(@"flowWithEntityName requestingPerform");
    [self.mainMoc performBlockAndWait:^{
        object = [self internalObjectWithEntityName:name predicate:predicate];
    }];
    MCLogVerbose(@"flowWithEntityName performed");
    return object;
}

- (NSManagedObject *)internalObjectWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate
{
    NSManagedObject *object = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:name];
    request.predicate = predicate;
    NSError *error = nil;
    NSArray *datas = [self.mainMoc executeFetchRequest:request error:&error];
    if (!datas) {
        MCLogError(@"[PWPersistenceController] flowWithEntityName %@", error);
    }else {
        if (datas.count) {
            object = datas.lastObject;
        }
    }
    return object;
}

- (void)deleteObject:(NSManagedObject *)object
{
    [self.mainMoc performBlockAndWait:^{
        [self.mainMoc deleteObject:object];
    }];
}

- (void)deleteObjectWithEntityName:(NSString *)name
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:name inManagedObjectContext:self.mainMoc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setIncludesPropertyValues:NO];
    [request setEntity:entity];
    NSError *error = nil;
    NSArray *datas = [self.mainMoc executeFetchRequest:request error:&error];
    if (!error && datas && [datas count]) {
        
        for (NSManagedObject *obj in datas) {
            
            [self deleteObject:obj];
        }
        
        [self save];
    }
}

- (NSFetchedResultsController *)fetchedResultsControllerWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate sortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:name];
    request.predicate = predicate;
    request.sortDescriptors = sortDescriptors;
    return [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.mainMoc sectionNameKeyPath:sectionNameKeyPath cacheName:nil];
}

- (void)asyncFindObjectWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate sortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors andFinalResultBlock:(void (^)(NSArray *finalResult))finalResult
{
    [self asyncFindObjectWithEntityName:name predicate:predicate sortDescriptors:sortDescriptors fetchLimit:0 fetchOffset:0 andFinalResultBlock:finalResult];
}

- (void)asyncFindObjectWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate sortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors fetchLimit:(NSInteger)fetchLimit fetchOffset:(NSInteger)fetchOffset andFinalResultBlock:(void (^)(NSArray *finalResult))finalResult
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:name];
    request.predicate = predicate;
    request.sortDescriptors = sortDescriptors;
    request.fetchLimit = fetchLimit;
    [request setFetchOffset:fetchOffset];
    // 异步查询request 在主线程回调
    NSAsynchronousFetchRequest *asynFetchRequest = [[NSAsynchronousFetchRequest alloc] initWithFetchRequest:request completionBlock:^(NSAsynchronousFetchResult * _Nonnull result) {
        finalResult(result.finalResult);
    }];
    NSError *error = nil;
    
    [self.mainMoc executeRequest:asynFetchRequest error:&error];
    if (error) {
        MCLogError(@"!!! Error: count objects in main context !!!\n%@\n", [error localizedDescription]);
    }
}

- (void)save
{
    [self.mainMoc performBlockAndWait:^{
        [self internalSync];
    }];
}

- (void)internalSync
{
    if ([self.mainMoc hasChanges] || [self.persistingMoc hasChanges]) {
        MCLogVerbose(@"[MARS DT Persistence] pre-sync: i%lu u%lu d%lu",
                     (unsigned long)self.mainMoc.insertedObjects.count,
                     (unsigned long)self.mainMoc.updatedObjects.count,
                     (unsigned long)self.mainMoc.deletedObjects.count
                     );
        NSError *error = nil;
        if (![self.mainMoc save:&error]) {
             MCLogError(@"!!! Error: save managed object in main context !!!\n%@\n", [error localizedDescription]);
        }
        [self.persistingMoc performBlock:^{
            NSError *error = nil;
            if (![self.persistingMoc save:&error]) {
                 MCLogError(@"!!! Error: save managed object in persisting context !!!\n%@\n", [error localizedDescription]);
            }
        }];
        if (self.mainMoc.hasChanges) {
             MCLogError(@"[MARS DT Persistence] sync not complete");
        }
        MCLogVerbose(@"[MARS DT Persistence] postsync: i%lu u%lu d%lu",
                     (unsigned long)self.mainMoc.insertedObjects.count,
                     (unsigned long)self.mainMoc.updatedObjects.count,
                     (unsigned long)self.mainMoc.deletedObjects.count
                     );
        
    }
}

- (void)rollback
{
    [self.mainMoc performBlockAndWait:^{
        if ([self.mainMoc hasChanges] || [self.persistingMoc hasChanges]) {
            [self.mainMoc rollback];
            [self.persistingMoc performBlock:^{
                [self.persistingMoc rollback];
            }];
        }
    }];
}

- (void)reset
{
    [self.mainMoc performBlockAndWait:^{
        if ([self.mainMoc hasChanges] || [self.persistingMoc hasChanges]) {
            [self.mainMoc reset];
            [self.persistingMoc performBlock:^{
                [self.persistingMoc reset];
            }];
        }
    }];
}

- (void)createObjectWithEntityName:(NSString *)name primaryKey:(NSString *)primaryKey dataArray:(NSArray *)dataArray completion:(void (^)(BOOL finished))completion;
{
    NSAssert(name != nil && primaryKey != nil, @"name and primaryKey Can't be empty");
    dispatch_barrier_async(self.synchronizationQueue, ^{
        NSLog(@"begin createObject");
        [dataArray enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop) {
            
            id primaryValue = dict[primaryKey];
            NSAssert(primaryValue != nil, @"fetchValue Can't be empty");
            NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ = %@", primaryKey, primaryValue]];
            NSArray *allKeys = [dict allKeys];
            NSManagedObject *object = [self createObjectWithEntityName:name predicate:predicate];
            if (!object) {
                return;
            }
            NSDictionary *attributesByName = object.entity.attributesByName;
            
            for (NSString *key in allKeys) {
                id value = dict[key];
                if ([value isKindOfClass:[NSNull class]]) {
                    value = nil;
                }
                NSAttributeDescription *attributeDescription = attributesByName[key];
                if (attributeDescription.attributeValueClassName && [attributeDescription.attributeValueClassName isEqualToString:@"NSNumber"] && [value isKindOfClass:[NSNumber class]] == NO) {
                    value = @(0);
                }
                NSLog(@"key = %@ , value = %@", key ,dict[key]);
                [object willChangeValueForKey:key];
                [object setValue:value forKey:key];
                [object didChangeValueForKey:key];
            }
        }];
        [[PWPersistenceController sharedInstance] save];
        if (completion) {
            completion(YES);
        }
        NSLog(@"end createObject");
    });
}

@end
