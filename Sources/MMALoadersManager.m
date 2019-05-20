//
//  MMALoadersManager.m
//  MSTRnLoader
//
//  Created by Fan Li Lin on 2019/4/25.
//  Copyright © 2019 puwang. All rights reserved.
//

#import "MMALoadersManager.h"
#import "MSTFileDownloadToken.h"
#import "MSTFileDownloader.h"
#import "MSTRnLoaderMacros.h"

@interface MMALoadersManager ()
@property (strong, nonatomic) NSMutableDictionary *allDownloadToken;
/*&* A lock to keep the access to `URLOperations` thread-safe */
@property (strong, nonatomic) dispatch_semaphore_t operationsLock;
@end

@implementation MMALoadersManager

+ (NSURL *)bundleURLWithLastPath:(NSString *)lastPath
{
    NSString *downloadDir = [MSTFileDownloaderConfig downloadDir];
    NSString *bundlePath = [downloadDir stringByAppendingPathComponent:lastPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:bundlePath isDirectory:NULL]) {
        NSURL *bundleURL = [NSURL fileURLWithPath:bundlePath];
        return bundleURL;
    }
    return nil;
}

+ (instancetype)sharedManager
{
    static MMALoadersManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _allDownloadToken = [NSMutableDictionary new];
        _operationsLock = dispatch_semaphore_create(1);
    }
    return self;
}

- (MSTFileDownloadToken *)downloadFileWithURL:(NSURL *)url
                                  ownFileName:(NSString *)ownFileName
                               taskIdentifier:(NSString *)taskIdentifier
                                     progress:(void(^)(NSProgress *downloadProgress, MSTFileDownloadToken *tokenTask))progressBlock
                                  unzProgress:(void(^)(long entryNumber, long total, MSTFileDownloadToken *tokenTask))unzProgressBlock
                                    completed:(void (^)(NSURLResponse *response, NSString *filePath, NSError *error))completedBlock;
{
    NSAssert(url != nil, @"download url Can't be empty");
    __block id objectForKey = taskIdentifier ? : url;
    __block MSTFileDownloadToken *downloadToken = [self.allDownloadToken objectForKey:objectForKey];
    @weakify(self);
    if (!downloadToken) {
        downloadToken = [[MSTFileDownloader sharedDownloader] downloadFileWithURL:url ownFileName:ownFileName taskIdentifier:taskIdentifier progress:^(NSProgress *downloadProgress, NSString *taskIdentifier) {
            @strongify(self);
            if (!self) {
                return;
            }
            if (progressBlock) {
                progressBlock(downloadProgress, downloadToken);
            }
        } unzProgress:^(long entryNumber, long total) {
            @strongify(self);
            if (!self) {
                return;
            }
            if (unzProgressBlock) {
                unzProgressBlock(entryNumber, total, downloadToken);
            }
        } completed:^(NSURLResponse *response, NSString *filePath, NSError *error) {
            @strongify(self);
            if (!self) {
                return;
            }
            if (completedBlock) {
                completedBlock(response, filePath, error);
            }
            MST_LOCK(self.operationsLock);
            [self.allDownloadToken removeObjectForKey:objectForKey];
            MST_UNLOCK(self.operationsLock);
        }];
        self.allDownloadToken[objectForKey] = downloadToken;
    }else {
        [downloadToken listenerForProgress:^(NSProgress *downloadProgress, NSString *taskIdentifier) {
            @strongify(self);
            if (!self) {
                return;
            }
            if (progressBlock) {
                progressBlock(downloadProgress, downloadToken);
            }
            
        } unzProgress:^(long entryNumber, long total) {
            @strongify(self);
            if (!self) {
                return;
            }
            if (unzProgressBlock) {
                unzProgressBlock(entryNumber, total, downloadToken);
            }
        } completed:^(NSURLResponse *response, NSString *filePath, NSError *error) {
            @strongify(self);
            if (!self) {
                return;
            }
            if (completedBlock) {
                completedBlock(response, filePath, error);
            }
            MST_LOCK(self.operationsLock);
            [self.allDownloadToken removeObjectForKey:objectForKey];
            MST_UNLOCK(self.operationsLock);
        }];
    }
    return downloadToken;
}

@end
