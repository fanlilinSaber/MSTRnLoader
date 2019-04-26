//
//  PWPersistenceController.h
//  Warehouse
//
//  Created by Fan Li Lin on 2018/11/13.
//  Copyright © 2018 FLL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/**
 *  *&* 数据库 CoreData 快捷使用类 *
 */
@interface PWPersistenceController : NSObject

/**
 init
 
 @return 单例管理
 */
+ (instancetype)sharedInstance;

/**
 查询

 @param name 实体对象的 name
 @param predicate predicate
 @param sortDescriptors sortDescriptors
 @return 返回查询 包含实体对象的数组
 */
- (NSArray *)findObjectWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate sortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors;

/**
 根据 objectId 查询

 @param objectId objectId
 @return 返回 实体对象 Object
 */
- (NSManagedObject *)findObjectById:(NSManagedObjectID *)objectId;

/**
 查询实体对象的 count

 @param name 实体对象的 name
 @param predicate predicate
 @return 返回 查询的实体对象的数量
 */
- (NSUInteger)countObjectWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate;

/**
 创建实体对象

 @param name 实体对象的 name
 @return 返回实体对象
 */
- (NSManagedObject *)createObjectWithEntityName:(NSString *)name;

/**
 删除对应实体对象数据

 @param object 实体对象 Objects
 */
- (void)deleteObject:(NSManagedObject *)object;

/**
 删除对应实体对象的所有数据

 @param name 实体对象 name
 */
- (void)deleteObjectWithEntityName:(NSString *)name;

/**
 The `NSFetchedResultsController` to be used by the data source.

 @param name 实体对象 name
 @param predicate predicate
 @param sortDescriptors sortDescriptors
 @param sectionNameKeyPath sectionNameKeyPath
 @return 返回一个 NSFetchedResultsController
 */
- (NSFetchedResultsController *)fetchedResultsControllerWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate sortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors sectionNameKeyPath:(NSString *)sectionNameKeyPath;

/**
 异步查询

 @param name 实体对象的 name
 @param predicate predicate
 @param sortDescriptors sortDescriptors
 @param finalResult 返回最终数据的 block
 */
- (void)asyncFindObjectWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate sortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors andFinalResultBlock:(void (^)(NSArray *finalResult))finalResult;

/**
 异步查询

 @param name 实体对象的 name
 @param predicate predicate
 @param sortDescriptors sortDescriptors
 @param fetchLimit 页数
 @param fetchOffset 偏移量
 @param finalResult 返回最终数据的 block
 */
- (void)asyncFindObjectWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate sortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors fetchLimit:(NSInteger)fetchLimit fetchOffset:(NSInteger)fetchOffset andFinalResultBlock:(void (^)(NSArray *finalResult))finalResult;

/**
 持久化
 */
- (void)save;

/**
 回滚
 */
- (void)rollback;

/**
 重置 （清除缓存的 Managed Objects 添加或删除之后）
 */
- (void)reset;


- (void)createObjectWithEntityName:(NSString *)name primaryKey:(NSString *)primaryKey dataArray:(NSArray *)dataArray completion:(void (^)(BOOL finished))completion;

@end

