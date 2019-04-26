//
//  MSTFileManager.h
//  MSTRnLoader
//
//  Created by Fan Li Lin on 2019/4/25.
//  Copyright © 2019 puwang. All rights reserved.
//  这是文件管理操作类

#import <Foundation/Foundation.h>

@interface MSTFileManager : NSObject

/**
 创建文件目录，如果有直接返回 YES ，没有就重新创建

 @param path 文件目录
 @return YES：成功，NO：失败
 */
- (BOOL)createDirectoryAtPath:(NSString *)path;

/**
 解压文件

 @param path 被解压的文件路径
 @param destination 解压后的文件路径
 @param progressHandler 解压进度回调
 @param completionHandler 解压完成回调
 */
- (void)unzipFileAtPath:(NSString *)path
          toDestination:(NSString *)destination
        progressHandler:(void (^)(NSString *entry, long entryNumber, long total))progressHandler
      completionHandler:(void (^)(NSString *path, BOOL succeeded, NSError *error))completionHandler;

/**
 差异化文件更新

 @param path 差异化补丁文件路径 （服务器下载）
 @param origin 源文件路径
 @param destination 需要被差异化更新的文件路径 （服务器下载）
 @param completionHandler 更新完成回调
 */
- (void)bsdiffFileAtPath:(NSString *)path
              fromOrigin:(NSString *)origin
           toDestination:(NSString *)destination
       completionHandler:(void (^)(BOOL success))completionHandler;

- (void)copyFiles:(NSDictionary *)filesDic
          fromDir:(NSString *)fromDir
            toDir:(NSString *)toDir
          deletes:(NSDictionary *)deletes
completionHandler:(void (^)(NSError *error))completionHandler;

- (void)removeFile:(NSString *)filePath
 completionHandler:(void (^)(NSError *error))completionHandler;

@end


