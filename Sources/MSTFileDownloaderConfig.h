//
//  MSTFileDownloaderConfig.h
//  MSTRnLoader
//
//  Created by Fan Li Lin on 2019/4/19.
//  Copyright © 2019 puwang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSTFileDownloaderConfig : NSObject
/*&* 这是默认的下载器配置; 大多数配置属性都支持在下载过程中进行动态更改 */
@property (nonatomic, class, readonly, nonnull) MSTFileDownloaderConfig *defaultDownloaderConfig;
/*&* 并发下载最大数，默认 6 */
@property (nonatomic, assign) NSInteger maxConcurrentDownloads;
/*&* 每个下载任务超时，以秒为单位，默认 15.0 */
@property (nonatomic, assign) NSTimeInterval downloadTimeout;

+ (NSString *)downloadDir;

@end

NS_ASSUME_NONNULL_END
