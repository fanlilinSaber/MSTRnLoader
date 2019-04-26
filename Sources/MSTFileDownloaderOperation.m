//
//  MSTFileDownloaderOperation.m
//  MSTRnLoader
//
//  Created by Fan Li Lin on 2019/4/22.
//  Copyright © 2019 puwang. All rights reserved.
//

#import "MSTFileDownloaderOperation.h"
#import "MSTFileDownloaderError.h"
#import "MSTFileManager.h"
#import "MSTRnLoaderMacros.h"

static NSString *const kProgressCallbackKey = @"progress";
static NSString *const kUnzProgressCallbackKey = @"unzProgress";
static NSString *const kCompletedCallbackKey = @"completed";

typedef NSMutableDictionary<NSString *, id> MSTCallbacksDictionary;

@interface MSTFileDownloaderOperation ()
@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;
/*&* 回调block */
@property (nonatomic, strong) NSMutableArray<MSTCallbacksDictionary *> *callbackBlocks;
/*&* 下载管理器 */
@property (nonatomic, weak) AFHTTPSessionManager *outerManager;
/*&* dataTask */
@property (strong, nonatomic) NSURLSessionTask *dataTask;
/*&* a lock to keep the access to `callbackBlocks` thread-safe */
@property (strong, nonatomic, nonnull) dispatch_semaphore_t callbacksLock;
/*&* 后台任务id */
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;
/*&* fileManager */
@property (nonatomic, strong) MSTFileManager *fileManager;
/*&* 文件名 */
@property (nonatomic, copy) NSString *ownFileName;
/*&* 下载进度 */
@property (assign, nonatomic, readwrite) float progress;
/*&* 下载文件总大小 */
@property (assign, nonatomic, readwrite) int64_t totalUnitCount;
/*&* 已下载文件的大小 */
@property (assign, nonatomic, readwrite) int64_t completedUnitCount;
/*&* 解压index */
@property (assign, nonatomic, readwrite) long entryNumber;
/*&* 解压文件数量 */
@property (assign, nonatomic, readwrite) long total;
/*&* 下载状态 */
@property (assign, assign, readwrite) MSTFileDownloaderState state;
@end

@implementation MSTFileDownloaderOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
}


- (instancetype)initWithRequest:(NSURLRequest *)request
                 sessionManager:(AFHTTPSessionManager *)manager
                        options:(MSTFileDownloaderOptions)options
                    ownFileName:(NSString *)ownFileName
{
    self = [super init];
    if (self) {
        _request = [request copy];
        _ownFileName = [ownFileName copy];
        _options = options;
        _outerManager = manager;
        _callbackBlocks = [NSMutableArray new];
        _fileManager = [MSTFileManager new];
        _executing = NO;
        _finished = NO;
        _callbacksLock = dispatch_semaphore_create(1);
        _backgroundTaskId = UIBackgroundTaskInvalid;
        _state = MSTFileDownloaderStateReadying;
    }
    return self;
}

- (id)addHandlersForProgress:(MSTFileDownloaderProgressBlock)progressBlock
                 unzProgress:(MSTFileDownloaderUNZProgressBlock)unzProgressBlock
                   completed:(MSTFileDownloaderCompletedBlock)completedBlock
{
    MSTCallbacksDictionary *callbacks = [NSMutableDictionary new];
    if (progressBlock) callbacks[kProgressCallbackKey] = [progressBlock copy];
    if (unzProgressBlock) callbacks[kUnzProgressCallbackKey] = [unzProgressBlock copy];
    if (completedBlock) callbacks[kCompletedCallbackKey] = [completedBlock copy];
    MST_LOCK(self.callbacksLock);
    [self.callbackBlocks addObject:callbacks];
    MST_UNLOCK(self.callbacksLock);
    return callbacks;
}

- (id)setHandlersForToken:(id)token
                 progress:(MSTFileDownloaderProgressBlock)progressBlock
              unzProgress:(MSTFileDownloaderUNZProgressBlock)unzProgressBlock
                completed:(MSTFileDownloaderCompletedBlock)completedBlock
{
    if (!token) {
        token = [NSMutableDictionary new];
    }
    MSTCallbacksDictionary *callbacks = token;
    callbacks[kProgressCallbackKey] = [progressBlock copy];
    callbacks[kUnzProgressCallbackKey] = [unzProgressBlock copy];
    callbacks[kCompletedCallbackKey] = [completedBlock copy];
    MST_LOCK(self.callbacksLock);
    if (![self.callbackBlocks containsObject:token]) {
        [self.callbackBlocks addObject:callbacks];
    }
    MST_UNLOCK(self.callbacksLock);
    return callbacks;
}

- (NSArray<id> *)callbacksForKey:(NSString *)key
{
    MST_LOCK(self.callbacksLock);
    NSMutableArray<id> *callbacks = [[self.callbackBlocks valueForKey:key] mutableCopy];
    MST_UNLOCK(self.callbacksLock);
    // We need to remove [NSNull null] because there might not always be a progress block for each callback
    [callbacks removeObjectIdenticalTo:[NSNull null]];
    return [callbacks copy]; // strip mutability here
}

- (BOOL)cancel:(id)token
{
    BOOL shouldCancel = NO;
    MST_LOCK(self.callbacksLock);
    [self.callbackBlocks removeObjectIdenticalTo:token];
    if (self.callbackBlocks.count == 0) {
        shouldCancel = YES;
    }
    MST_UNLOCK(self.callbacksLock);
    if (shouldCancel) {
        [self cancel];
    }
    return shouldCancel;
}

- (void)start
{
    @synchronized (self) {
        if (self.isCancelled) {
            self.finished = YES;
            [self reset];
            return;
        }
        
        @weakify(self);
        Class UIApplicationClass = NSClassFromString(@"UIApplication");
        BOOL hasApplication = UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)];
        if (hasApplication && [self shouldContinueWhenAppEntersBackground]) {
            UIApplication * app = [UIApplicationClass performSelector:@selector(sharedApplication)];
            self.backgroundTaskId = [app beginBackgroundTaskWithExpirationHandler:^{
                @strongify(self);
                [self cancel];
            }];
        }

        // create file
        __block NSString *dir = [MSTFileDownloaderOperation downloadDir];
        BOOL success = [self.fileManager createDirectoryAtPath:dir];
        if (!success) {
            [self callCompletionBlocksWithError:[NSError errorWithDomain:MSTFileDownloaderErrorDomain code:MSTFileDownloaderErrorCreateFileDirectory userInfo:@{NSLocalizedDescriptionKey : @"file create operation error"}]];
            self.finished = YES;
            [self reset];
            return;
        }

        // create dataTask
        self.dataTask = [self.outerManager downloadTaskWithRequest:self.request progress:^(NSProgress * _Nonnull downloadProgress) {
            @strongify(self);
            self.totalUnitCount = downloadProgress.totalUnitCount;
            self.completedUnitCount = downloadProgress.completedUnitCount;
            self.progress = 1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount;
            // send block
            for (MSTFileDownloaderProgressBlock progressBlock in [self callbacksForKey:kProgressCallbackKey]) {
                progressBlock(downloadProgress, self.request.URL.path);
            }
            
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            @strongify(self);
            NSString *zipFilePath;
            if (self.ownFileName) {
                zipFilePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",self.ownFileName]];

            }else {
                zipFilePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",response.suggestedFilename]];
                self.ownFileName = [response.suggestedFilename copy];
            }
            return [NSURL fileURLWithPath:zipFilePath];

        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            @strongify(self);
            if (!error) {
                NSString *unzipFilePath = [dir stringByAppendingPathComponent:self.ownFileName];
                [self unzipFileAtPath:filePath.path toDestination:unzipFilePath response:response];
            }else {
                self.state = MSTFileDownloaderStateFailed;
                [self callCompletionBlocksWithError:error];
                [self done];
            }
        }];
        
        self.executing = YES;
    }
    
    if (self.dataTask) {
        // resume
        [self.dataTask resume];
        // send block
        for (MSTFileDownloaderProgressBlock progressBlock in [self callbacksForKey:kProgressCallbackKey]) {
            progressBlock([NSProgress new], self.request.URL.path);
        }
        _state = MSTFileDownloaderStateRunning;
    }else {
        [self callCompletionBlocksWithError:[NSError errorWithDomain:MSTFileDownloaderErrorDomain code:MSTFileDownloaderErrorInvalidDownloadOperation userInfo:@{NSLocalizedDescriptionKey : @"Task can't be initialized"}]];
        [self done];
    }
}

- (void)cancel
{
    @synchronized (self) {
        [self cancelInternal];
    }
}

- (void)cancelInternal
{
    if (self.isFinished) return;
    [super cancel];
    
    if (self.dataTask) {
        [self.dataTask cancel];
        
        // As we cancelled the task, its callback won't be called and thus won't
        // maintain the isFinished and isExecuting flags.
        if (self.isExecuting) self.executing = NO;
        if (!self.isFinished) self.finished = YES;
    }
    
    [self reset];
}

- (void)done
{
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

- (void)reset
{
    MST_LOCK(self.callbacksLock);
    [self.callbackBlocks removeAllObjects];
    MST_UNLOCK(self.callbacksLock);
    
    @synchronized (self) {
        self.dataTask = nil;
        
        if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
            // If backgroundTaskId != UIBackgroundTaskInvalid, sharedApplication is always exist
            UIApplication * app = [UIApplication performSelector:@selector(sharedApplication)];
            [app endBackgroundTask:self.backgroundTaskId];
            self.backgroundTaskId = UIBackgroundTaskInvalid;
        }
    }
    self.state = MSTFileDownloaderStateNone;
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent
{
    return YES;
}

#pragma mark - private method

- (void)unzipFileAtPath:(NSString *)filePath
          toDestination:(NSString *)destination
               response:(NSURLResponse *)response
{
    NSLog(@"下载文件成功...开始解压...");
    _state = MSTFileDownloaderStateRunningUnzip;
    for (MSTFileDownloaderUNZProgressBlock progressBlock in [self callbacksForKey:kUnzProgressCallbackKey]) {
        progressBlock(0, 0);
    }
    @weakify(self);
    [self.fileManager unzipFileAtPath:filePath toDestination:destination progressHandler:^(NSString *entry,long entryNumber, long total) {
        @strongify(self);
        self.entryNumber = entryNumber;
        self.total = total;
        // send block
        for (MSTFileDownloaderUNZProgressBlock progressBlock in [self callbacksForKey:kUnzProgressCallbackKey]) {
            progressBlock(entryNumber, total);
        }
        
    } completionHandler:^(NSString *path, BOOL succeeded, NSError *error) {
        @strongify(self);
        if (error) {
            self.state = MSTFileDownloaderStateFailedUnzip;
            [self callCompletionBlocksWithError:error];
            NSLog(@"解压失败...");
        }else {
            self.state = MSTFileDownloaderStateCompleted;
            [self callCompletionBlocksWithFilePath:destination response:response error:error];
            NSLog(@"解压成功...");
        }
        [self done];
    }];
}

- (BOOL)shouldContinueWhenAppEntersBackground
{
    return self.options & MSTFileDownloaderContinueInBackground;
}

- (void)callCompletionBlocksWithError:(NSError *)error
{
    [self callCompletionBlocksWithFilePath:nil response:nil error:error];
}

- (void)callCompletionBlocksWithFilePath:(NSString *)filePath
                                response:(NSURLResponse *)response
                                   error:(NSError *)error
{
    NSArray<id> *completionBlocks = [self callbacksForKey:kCompletedCallbackKey];
    dispatch_main_async_safe(^{
        for (MSTFileDownloaderCompletedBlock completedBlock in completionBlocks) {
            completedBlock(response, filePath, error);
        }
    });
}

+ (NSString *)downloadDir
{
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *downloadDir = [directory stringByAppendingPathComponent:@"reactnativecnlocal"];
    return downloadDir;
}

@end
