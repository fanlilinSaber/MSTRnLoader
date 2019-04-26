//
//  MSTFileDownloadToken.h
//  MSTRnLoader
//
//  Created by Fan Li Lin on 2019/4/22.
//  Copyright © 2019 puwang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSTWebFileOperation.h"

@protocol MSTFileDownloaderOperation;
@class MSTFileDownloader;

/**
 A token associated with each download. Can be used to cancel a download
 */
@interface MSTFileDownloadToken : NSObject <MSTWebFileOperation>
/*&* 下载 URL */
@property (nonatomic, strong, readonly) NSURL *url;
/*&* 取消下载token */
@property (nonatomic, strong, readonly) id downloadOperationCancelToken;
/*&* 任务标识,跟下载队列没有关系，用于多个下载的地址一样时，返回对比数据 */
@property (nonatomic, copy, readonly) NSString *taskIdentifier;
/*&* 下载进度 */
@property (assign, nonatomic, readonly) float progress;
/*&* 解压进度 */
@property (assign, nonatomic, readonly) float unzProgress;
/*&* 下载文件总大小 */
@property (assign, nonatomic, readonly) int64_t totalUnitCount;
/*&* 已下载文件的大小 */
@property (assign, nonatomic, readonly) int64_t completedUnitCount;
/*&* 解压index */
@property (assign, nonatomic, readwrite) long entryNumber;
/*&* 解压文件数量 */
@property (assign, nonatomic, readwrite) long total;
/*&* 下载状态 */
@property (assign, assign, readonly) MSTFileDownloaderState state;

- (instancetype)initWithDownloadOperation:(NSOperation<MSTFileDownloaderOperation> *)downloadOperation
                                      url:(NSURL *)url 
                           taskIdentifier:(NSString *)taskIdentifier
                               downloader:(MSTFileDownloader *)downloader
             downloadOperationCancelToken:(id)downloadOperationCancelToken;

- (MSTFileDownloadToken *)listenerForProgress:(MSTFileDownloaderProgressBlock)progressBlock
                                  unzProgress:(MSTFileDownloaderUNZProgressBlock)unzProgressBlock
                                    completed:(MSTFileDownloaderCompletedBlock)completedBlock;
/**
 取消当前下载
 */
- (void)cancel;

@end

