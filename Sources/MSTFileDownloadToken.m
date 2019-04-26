//
//  MSTFileDownloadToken.m
//  MSTRnLoader
//
//  Created by Fan Li Lin on 2019/4/22.
//  Copyright © 2019 puwang. All rights reserved.
//

#import "MSTFileDownloadToken.h"
#import "MSTFileDownloader.h"
#import "MSTFileDownloaderOperation.h"
#import "MSTRnLoaderMacros.h"

@interface MSTFileDownloadToken ()
@property (nonatomic, strong, readwrite) NSURL *url;
@property (nonatomic, strong, readwrite) NSURLRequest *request;
@property (nonatomic, strong, readwrite) id downloadOperationCancelToken;
@property (nonatomic, weak) NSOperation<MSTFileDownloaderOperation> *downloadOperation;
@property (nonatomic, weak) MSTFileDownloader *downloader;
@property (nonatomic, assign, getter=isCancelled) BOOL cancelled;
@property (nonatomic, assign) BOOL reuse;
@property (nonatomic, copy, readwrite) NSString *taskIdentifier;
@property (assign, nonatomic, readwrite) float progress;
@property (assign, nonatomic, readwrite) float unzProgress;
@property (assign, nonatomic, readwrite) int64_t totalUnitCount;
@property (assign, nonatomic, readwrite) int64_t completedUnitCount;
@property (assign, nonatomic, readwrite) int64_t unzTotalUnitCount;
@property (assign, nonatomic, readwrite) int64_t unzCompletedUnitCount;
@property (assign, assign, readwrite) MSTFileDownloaderState state;
@end

@implementation MSTFileDownloadToken

- (instancetype)initWithDownloadOperation:(NSOperation<MSTFileDownloaderOperation> *)downloadOperation
                                      url:(NSURL *)url
                           taskIdentifier:(NSString *)taskIdentifier
                               downloader:(MSTFileDownloader *)downloader
             downloadOperationCancelToken:(id)downloadOperationCancelToken;
{
    self = [super init];
    if (self) {
        _downloadOperation = downloadOperation;
        _url = url;
        _taskIdentifier = taskIdentifier;
        _downloader = downloader;
        _downloadOperationCancelToken = downloadOperationCancelToken;
    }
    return self;
}

- (void)cancel
{
    @synchronized (self) {
        if (self.isCancelled) {
            return;
        }
        self.cancelled = YES;
        if (self.downloader) {
            // Downloader is alive, cancel token
            [self.downloader cancel:self];
        } else {
            // Downloader is dealloced, only cancel download operation
            [self.downloadOperation cancel:self.downloadOperationCancelToken];
        }
        self.downloadOperationCancelToken = nil;
    }
}

- (MSTFileDownloadToken *)listenerForProgress:(MSTFileDownloaderProgressBlock)progressBlock
                                  unzProgress:(MSTFileDownloaderUNZProgressBlock)unzProgressBlock
                                    completed:(MSTFileDownloaderCompletedBlock)completedBlock
{
    _downloadOperationCancelToken = [self.downloadOperation setHandlersForToken:_downloadOperationCancelToken progress:progressBlock unzProgress:unzProgressBlock completed:completedBlock];
    
    return self;
}

#pragma mark - getters and setters

- (float)progress
{
    if (self.downloadOperation) {
        self.progress = self.downloadOperation.progress;
        return self.downloadOperation.progress;
    }
    return self.progress;
}

- (int64_t)totalUnitCount
{
    if (self.downloadOperation) {
        self.totalUnitCount = self.downloadOperation.totalUnitCount;
        return self.downloadOperation.totalUnitCount;
    }
    return self.totalUnitCount;
}

- (int64_t)completedUnitCount
{
    if (self.downloadOperation) {
        self.completedUnitCount = self.downloadOperation.completedUnitCount;
    }
    return self.completedUnitCount;
}

- (long)entryNumber
{
    if (self.downloadOperation) {
        self.entryNumber = self.downloadOperation.entryNumber;
    }
    return self.entryNumber;
}

- (long)total
{
    if (self.downloadOperation) {
        self.total = self.downloadOperation.total;
    }
    return self.total;
}

@end
