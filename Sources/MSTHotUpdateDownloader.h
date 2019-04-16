//
//  MSTHotUpdateDownloader.h
//  MARS
//
//  Created by Fan Li Lin on 2019/4/16.
//  Copyright © 2019 puwang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSTHotUpdateDownloader : NSObject

+ (void)download:(NSString *)downloadPath
        savePath:(NSString *)savePath
 progressHandler:(void (^)(long long, long long))progressHandler
completionHandler:(void (^)(NSString *path, NSError *error))completionHandler;

@end

