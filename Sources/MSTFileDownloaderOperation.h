//
//  MSTFileDownloaderOperation.h
//  MSTRnLoader
//
//  Created by Fan Li Lin on 2019/4/22.
//  Copyright © 2019 puwang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "MSTFileDownloader.h"

typedef MSTFileDownloaderProgressBlock MSTFileDownloaderProgressBlock;
typedef MSTFileDownloaderCompletedBlock MSTFileDownloaderCompletedBlock;
typedef MSTFileDownloaderUNZProgressBlock MSTFileDownloaderUNZProgressBlock;

@protocol MSTFileDownloaderOperation <NSObject>
@required

- (instancetype)initWithRequest:(NSURLRequest *)request
                 sessionManager:(AFHTTPSessionManager *)manager
                        options:(MSTFileDownloaderOptions)options
                    ownFileName:(NSString *)ownFileName;

- (id)addHandlersForProgress:(MSTFileDownloaderProgressBlock)progressBlock
                 unzProgress:(MSTFileDownloaderUNZProgressBlock)unzProgressBlock
                   completed:(MSTFileDownloaderCompletedBlock)completedBlock;

- (id)setHandlersForToken:(id)token
                 progress:(MSTFileDownloaderProgressBlock)progressBlock
              unzProgress:(MSTFileDownloaderUNZProgressBlock)unzProgressBlock
                completed:(MSTFileDownloaderCompletedBlock)completedBlock;

- (BOOL)cancel:(id)token;

@property (strong, nonatomic, readonly) NSURLRequest *request;
@property (strong, nonatomic, readonly) NSURLResponse *response;
@property (assign, nonatomic, readonly) float progress;
@property (assign, nonatomic, readonly) int64_t totalUnitCount;
@property (assign, nonatomic, readonly) int64_t completedUnitCount;
@property (assign, nonatomic, readonly) long entryNumber;
@property (assign, nonatomic, readonly) long total;
@property (assign, assign, readonly) MSTFileDownloaderState state;
@end

/**
 *  *&* 一个下载操作器 *
 */
@interface MSTFileDownloaderOperation : NSOperation <MSTFileDownloaderOperation>
/*&* The request used by the operation's task. */
@property (strong, nonatomic, readonly) NSURLRequest *request;
/*&* The response returned by the operation's task. */
@property (strong, nonatomic, readonly) NSURLResponse *response;
/*&* The options for the receiver. */
@property (assign, nonatomic, readonly) MSTFileDownloaderOptions options;
/*&* 下载进度 */
@property (assign, nonatomic, readonly) float progress;
/*&* 下载文件总大小 */
@property (assign, nonatomic, readonly) int64_t totalUnitCount;
/*&* 已下载文件的大小 */
@property (assign, nonatomic, readonly) int64_t completedUnitCount;
/*&* 解压index */
@property (assign, nonatomic, readonly) long entryNumber;
/*&* 解压文件数量 */
@property (assign, nonatomic, readonly) long total;
/*&* 下载状态 */
@property (assign, assign, readonly) MSTFileDownloaderState state;

/**
 初始化下载队列

 @param request 下载任务请求
 @param manager 下载管理器
 @return 下载队列实例
 */
- (instancetype)initWithRequest:(NSURLRequest *)request
                 sessionManager:(AFHTTPSessionManager *)manager
                        options:(MSTFileDownloaderOptions)options
                    ownFileName:(NSString *)ownFileName;

/**
 下载进度和下载完成回调

 @param progressBlock 下载进度回调
 @param completedBlock 下载完成回调
 @param unzProgressBlock 解压进度
 @return 用来取消这组处理程序的 token
 */
- (id)addHandlersForProgress:(MSTFileDownloaderProgressBlock)progressBlock
                 unzProgress:(MSTFileDownloaderUNZProgressBlock)unzProgressBlock
                   completed:(MSTFileDownloaderCompletedBlock)completedBlock;

- (id)setHandlersForToken:(id)token
                 progress:(MSTFileDownloaderProgressBlock)progressBlock
              unzProgress:(MSTFileDownloaderUNZProgressBlock)unzProgressBlock
                completed:(MSTFileDownloaderCompletedBlock)completedBlock;

/**
 取消回调。一旦所有监听回调被取消，队列就被取消

 @param token 用来取消任务的 token
 @return YES
 */
- (BOOL)cancel:(id)token;

@end


