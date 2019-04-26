//
//  MSTFileDownloaderError.h
//  MSTRnLoader
//
//  Created by Fan Li Lin on 2019/4/23.
//  Copyright © 2019 puwang. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSErrorDomain const _Nonnull MSTFileDownloaderErrorDomain;

typedef NS_ERROR_ENUM(MSTFileDownloaderErrorDomain, MSTFileDownloaderError) {
    /**
     *  *&* 下载文件 URL 不可用 *
     */
    MSTFileDownloaderErrorInvalidURL = 1000,
    /**
     *  *&* 文件下载 Operation 初始化出错*
     */
    MSTFileDownloaderErrorInvalidDownloadOperation = 1001,
    /**
     *  *&* 创建下载文件目录 出错 *
     */
    MSTFileDownloaderErrorCreateFileDirectory = 1002
};
