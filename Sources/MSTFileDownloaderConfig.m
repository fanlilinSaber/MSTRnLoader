//
//  MSTFileDownloaderConfig.m
//  MSTRnLoader
//
//  Created by Fan Li Lin on 2019/4/19.
//  Copyright © 2019 puwang. All rights reserved.
//

#import "MSTFileDownloaderConfig.h"

static MSTFileDownloaderConfig * _defaultDownloaderConfig;

@implementation MSTFileDownloaderConfig

+ (MSTFileDownloaderConfig *)defaultDownloaderConfig
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultDownloaderConfig = [MSTFileDownloaderConfig new];
    });
    return _defaultDownloaderConfig;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _maxConcurrentDownloads = 6;
        _downloadTimeout = 15.0;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    MSTFileDownloaderConfig *config = [[[self class] allocWithZone:zone] init];
    config.maxConcurrentDownloads = self.maxConcurrentDownloads;
    config.downloadTimeout = self.downloadTimeout;
    return config;
}

@end
