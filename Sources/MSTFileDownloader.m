//
//  MSTFileDownloader.m
//  MSTRnLoader
//
//  Created by Fan Li Lin on 2019/4/19.
//  Copyright © 2019 puwang. All rights reserved.
//

#import "MSTFileDownloader.h"
#import <AFNetworking/AFNetworking.h>
#import "MSTFileDownloaderError.h"
#import "MSTRnLoaderMacros.h"
#import "MSTFileDownloaderOperation.h"

static void * MSTFileDownloaderContext = &MSTFileDownloaderContext;

@interface MSTFileDownloader ()
/*&* 下载队列 */
@property (nonatomic, strong) NSOperationQueue *downloadQueue;
/*&* manager */
@property (nonatomic, strong) AFHTTPSessionManager *manager;
/*&* 下载队列管理 */
@property (strong, nonatomic) NSMutableDictionary<NSURL *, NSOperation<MSTFileDownloaderOperation> *> *URLOperations;
/*&* A lock to keep the access to `URLOperations` thread-safe */
@property (strong, nonatomic) dispatch_semaphore_t operationsLock;
@end

@implementation MSTFileDownloader

+ (instancetype)sharedDownloader
{
    static MSTFileDownloader *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init
{
    return [self initWithConfig:MSTFileDownloaderConfig.defaultDownloaderConfig];
}

- (instancetype)initWithConfig:(MSTFileDownloaderConfig *)config
{
    self = [super init];
    if (self) {
        if (!config) {
            config = MSTFileDownloaderConfig.defaultDownloaderConfig;
        }
        _config = [config copy];
        [_config addObserver:self forKeyPath:NSStringFromSelector(@selector(maxConcurrentDownloads)) options:0 context:MSTFileDownloaderContext];
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = _config.maxConcurrentDownloads;
        _manager = [AFHTTPSessionManager manager];
        _operationsLock = dispatch_semaphore_create(1);
        _URLOperations = [NSMutableDictionary new];
    }
    return self;
}


- (void)dealloc
{
    [self.manager invalidateSessionCancelingTasks:YES];
    self.manager = nil;

    [self.downloadQueue cancelAllOperations];
    [self.config removeObserver:self forKeyPath:NSStringFromSelector(@selector(maxConcurrentDownloads)) context:MSTFileDownloaderContext];
}

- (MSTFileDownloadToken *)downloadFileWithURL:(NSURL *)url
                                       progress:(MSTFileDownloaderProgressBlock)progressBlock
                                    unzProgress:(MSTFileDownloaderUNZProgressBlock)unzProgressBlock
                                      completed:(MSTFileDownloaderCompletedBlock)completedBlock
{
    return [self downloadFileWithURL:url ownFileName:nil progress:progressBlock unzProgress:unzProgressBlock completed:completedBlock];
}

- (MSTFileDownloadToken *)downloadFileWithURL:(NSURL *)url
                                  ownFileName:(NSString *)ownFileName
                                     progress:(MSTFileDownloaderProgressBlock)progressBlock
                                  unzProgress:(MSTFileDownloaderUNZProgressBlock)unzProgressBlock
                                    completed:(MSTFileDownloaderCompletedBlock)completedBlock
{
    return [self downloadFileWithURL:url ownFileName:ownFileName taskIdentifier:url.relativeString progress:progressBlock unzProgress:unzProgressBlock completed:completedBlock];
}

- (MSTFileDownloadToken *)downloadFileWithURL:(NSURL *)url
                                  ownFileName:(NSString *)ownFileName
                               taskIdentifier:(NSString *)taskIdentifier
                                     progress:(MSTFileDownloaderProgressBlock)progressBlock
                                  unzProgress:(MSTFileDownloaderUNZProgressBlock)unzProgressBlock
                                    completed:(MSTFileDownloaderCompletedBlock)completedBlock
{
    if (url == nil) {
        if (completedBlock) {
            NSError *error = [NSError errorWithDomain:MSTFileDownloaderErrorDomain code:MSTFileDownloaderErrorInvalidURL userInfo:@{NSLocalizedDescriptionKey : @"download file url is nil"}];
            completedBlock(nil, nil, error);
        }
        return nil;
    }
    
    MST_LOCK(self.operationsLock);
    NSOperation<MSTFileDownloaderOperation> *operation = [self.URLOperations objectForKey:url];
    // 有可能 operation 被标记为已完成或者是取消，但是没有被删除
    if (!operation || operation.isFinished || operation.isCancelled) {
        operation = [self createDownloaderOperationWithUrl:url options:MSTFileDownloaderContinueInBackground ownFileName:ownFileName];
        if (!operation) {
            MST_UNLOCK(self.operationsLock);
            if (completedBlock) {
                NSError *error = [NSError errorWithDomain:MSTFileDownloaderErrorDomain code:MSTFileDownloaderErrorInvalidDownloadOperation userInfo:@{NSLocalizedDescriptionKey : @"Downloader operation is nil"}];
                completedBlock(nil, nil, error);
            }
            return nil;
        }
        
        @weakify(self);
        operation.completionBlock = ^{
            @strongify(self);
            if (!self) {
                return;
            }
            MST_LOCK(self.operationsLock);
            [self.URLOperations removeObjectForKey:url];
            MST_UNLOCK(self.operationsLock);
        };
        self.URLOperations[url] = operation;
        // add downloadQueue
        [self.downloadQueue addOperation:operation];
    }
    else if (!operation.isExecuting) {
        operation.queuePriority = NSOperationQueuePriorityNormal;
    }
    MST_UNLOCK(self.operationsLock);
    
    id downloadOperationCancelToken = [operation addHandlersForProgress:progressBlock unzProgress:unzProgressBlock completed:completedBlock];
    
    MSTFileDownloadToken *token = [[MSTFileDownloadToken alloc] initWithDownloadOperation:operation url:url taskIdentifier:taskIdentifier downloader:self downloadOperationCancelToken:downloadOperationCancelToken];
    
    return token;
}

- (NSOperation<MSTFileDownloaderOperation> *)createDownloaderOperationWithUrl:(NSURL *)url
                                                                      options:(MSTFileDownloaderOptions)options
                                                                  ownFileName:(NSString *)ownFileName
{
    NSTimeInterval timeoutInterval = self.config.downloadTimeout;
    if (timeoutInterval == 0.0) {
        timeoutInterval = 15.0;
    }
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:0 timeoutInterval:timeoutInterval];
    NSOperation<MSTFileDownloaderOperation> *operation = [[MSTFileDownloaderOperation alloc] initWithRequest:request sessionManager:self.manager options:options ownFileName:ownFileName];

    return operation;
}

- (void)cancel:(MSTFileDownloadToken *)token
{
    NSURL *url = token.url;
    if (!url) {
        return;
    }
    MST_LOCK(self.operationsLock);
    NSOperation<MSTFileDownloaderOperation> *operation = [self.URLOperations objectForKey:url];
    if (operation) {
        BOOL canceled = [operation cancel:token.downloadOperationCancelToken];
        if (canceled) {
            [self.URLOperations removeObjectForKey:url];
        }
    }
    MST_UNLOCK(self.operationsLock);
}

- (void)cancelAllDownloads
{
    [self.downloadQueue cancelAllOperations];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == MSTFileDownloaderContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(maxConcurrentDownloads))]) {
            self.downloadQueue.maxConcurrentOperationCount = self.config.maxConcurrentDownloads;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - getters and setters

- (BOOL)isSuspended
{
    return self.downloadQueue.isSuspended;
}

- (void)setSuspended:(BOOL)suspended
{
    self.downloadQueue.suspended = suspended;
}

- (NSUInteger)currentDownloadCount
{
    return self.downloadQueue.operationCount;
}

@end
