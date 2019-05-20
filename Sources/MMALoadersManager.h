//
//  MMALoadersManager.h
//  MSTRnLoader
//
//  Created by Fan Li Lin on 2019/4/25.
//  Copyright © 2019 puwang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MSTFileDownloadToken;

@interface MMALoadersManager : NSObject
/*&* 返回一个单例加载器 */
@property (nonatomic, class, readonly) MMALoadersManager *sharedManager;

- (MSTFileDownloadToken *)downloadFileWithURL:(NSURL *)url
                                  ownFileName:(NSString *)ownFileName
                               taskIdentifier:(NSString *)taskIdentifier
                                     progress:(void(^)(NSProgress *downloadProgress, MSTFileDownloadToken *tokenTask))progressBlock
                                  unzProgress:(void(^)(long entryNumber, long total, MSTFileDownloadToken *tokenTask))unzProgressBlock
                                    completed:(void (^)(NSURLResponse *response, NSString *filePath, NSError *error))completedBlock;

+ (NSURL *)bundleURLWithLastPath:(NSString *)lastPath;

@end

