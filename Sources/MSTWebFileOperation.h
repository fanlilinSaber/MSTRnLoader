//
//  MSTWebFileOperation.h
//  MSTRnLoader
//
//  Created by Fan Li Lin on 2019/4/23.
//  Copyright © 2019 puwang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  *&* 下载状态 *
 */
typedef NS_ENUM(NSUInteger, MSTFileDownloaderState) {
    /**
     *  *&* 未下载 或 下载取消了 *
     */
    MSTFileDownloaderStateNone,
    /**
     *  *&* 等待下载 *
     */
    MSTFileDownloaderStateReadying,
    /**
     *  *&* 正在下载 *
     */
    MSTFileDownloaderStateRunning,
    /**
     *  *&* 下载暂停 *
     */
    MSTFileDownloaderStateSuspended,
    /**
     *  *&* 下载并且解压完成 *
     */
    MSTFileDownloaderStateCompleted,
    /**
     *  *&* 下载失败 *
     */
    MSTFileDownloaderStateFailed,
    /**
     *  *&* 正在解压 *
     */
    MSTFileDownloaderStateRunningUnzip,
    /**
     *  *&* 解压失败 *
     */
    MSTFileDownloaderStateFailedUnzip
};

typedef void (^MSTFileDownloaderProgressBlock)(NSProgress *downloadProgress, NSString *taskIdentifier);
typedef void (^MSTFileDownloaderCompletedBlock)(NSURLResponse *response, NSString *filePath, NSError *error);
typedef void (^MSTFileDownloaderUNZProgressBlock)(long entryNumber, long total);

@protocol MSTWebFileOperation <NSObject>

- (void)cancel;

@end

// NSOperation conform to `MSTWebFileOperation`
@interface NSOperation (MSTWebFileOperation) <MSTWebFileOperation>

@end
