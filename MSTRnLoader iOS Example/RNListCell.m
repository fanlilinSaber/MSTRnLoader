//
//  RNListCell.m
//  MSTRnLoader iOS Example
//
//  Created by Fan Li Lin on 2019/4/23.
//  Copyright © 2019 puwang. All rights reserved.
//

#import "RNListCell.h"
#import <Masonry.h>
#import "MSTFileDownloader.h"
#import "MMALoadersManager.h"
#import "PWPersistenceController.h"

@implementation RNListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundView.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        [self.contentView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];

        // add
        
        self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 20, [[UIScreen mainScreen] bounds].size.width, 3)];
        self.progressView.progressTintColor = [UIColor blueColor];
//        self.progressView.progress = 0.5;
        [self.contentView addSubview:self.progressView];
        
        self.nameLabel = [UILabel new];
        self.nameLabel.textColor = [UIColor blackColor];
        
        self.versionLabel = [UILabel new];
        self.versionLabel.textColor = [UIColor redColor];
    
        self.stateLabel = [UILabel new];
        self.stateLabel.textColor = [UIColor blueColor];
        self.stateLabel.text = @" ";
        self.stateLabel.numberOfLines = 2;
        [self.stateLabel sizeToFit];
        self.stateLabel.adjustsFontSizeToFitWidth = YES;
        
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.versionLabel];
        [self.contentView addSubview:self.stateLabel];
        
        [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.imageView.mas_right);
            make.bottom.equalTo(self.contentView.mas_bottom);
            make.right.equalTo(self.contentView.mas_right);
            make.height.equalTo(@(3));
        }];
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.imageView.mas_right).offset(8);
            make.top.equalTo(self.contentView.mas_top).offset(8);
        }];
        [self.versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.nameLabel.mas_bottom).offset(8);
            make.left.equalTo(self.imageView.mas_right).offset(8);
        }];
        [self.stateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.contentView.mas_bottom).offset(-8);
            make.left.equalTo(self.imageView.mas_right).offset(8);
            make.right.equalTo(self.contentView.mas_right).offset(-8);
            make.top.equalTo(self.versionLabel.mas_bottom).offset(8);
        }];
    }
    return self;
}

- (void)setModel:(RNListModel *)model
{
    _model = model;
    self.nameLabel.text = model.rnAppInfo.name;
    self.progressView.progress = 0;
    self.versionLabel.text = [NSString stringWithFormat:@"mmaId = %d, version = %d",model.rnAppInfo.mmaId, model.rnAppInfo.version];
    NSLog(@"---%@",self.versionLabel.text);
    [self.imageView setImage:[UIImage imageNamed:@"ar_tagging_select"]];
    if (model.token) {
        if (self.model.rnAppInfo.bundleURL.length > 0 && self.token.state == MSTFileDownloaderStateNone) {
            self.stateLabel.text = @"已经下载了，可以直接加载";
        }else if (self.token.state == MSTFileDownloaderStateReadying) {
            self.stateLabel.text = @"等待下载";
        }else if (self.token.state == MSTFileDownloaderStateRunning) {
            self.stateLabel.text = @"正在下载";
        }else if (self.token.state == MSTFileDownloaderStateSuspended) {
            self.stateLabel.text = @"下载暂停";
        }else if (self.token.state == MSTFileDownloaderStateCompleted) {
            self.stateLabel.text = @"下载完成了";
        }else if (self.token.state == MSTFileDownloaderStateFailed) {
            self.stateLabel.text = @"下载失败了";
        }else if (self.token.state == MSTFileDownloaderStateRunningUnzip) {
            self.stateLabel.text = @"正在解压";
        }else if (self.token.state == MSTFileDownloaderStateFailedUnzip) {
            self.stateLabel.text = @"解压失败了";
        }
        self.progressView.progress = model.token.progress;
        [self updateDownloadForURL:[NSURL URLWithString:self.model.rnAppInfo.file]];

    }else {
        if (self.model.rnAppInfo.bundleURL.length > 0) {
            self.stateLabel.text = @"已经下载了，可以直接加载";
        }else {
            self.stateLabel.text = @"需要下载更新";
        }
    }
}

- (void)setToken:(MSTFileDownloadToken *)token
{
    _token = token;
    if (token != nil) {
        
    }
}

- (void)setTaskIdentifier:(NSString *)taskIdentifier
{
    _taskIdentifier = taskIdentifier;
    NSLog(@"taskIdentifier = %@",_taskIdentifier);
}

- (void)startDownloadForURL:(NSURL *)url
{
    self.URL = url;
    NSLog(@"下载地址：%@",url);
    self.stateLabel.text = @"开始下载...";
    self.progressView.progressTintColor = [UIColor blueColor];
    self.progressView.progress = 0;
    self.model.token = [self updateDownloadForURL:url];
//    __block MSTFileDownloadToken *token = [[MSTFileDownloader sharedDownloader] downloadFileWithURL:url ownFileName:fileName  taskIdentifier:self.taskIdentifier reuse:YES progress:^(NSProgress *downloadProgress, NSString *taskIdentifier) {
//
//        __strong __typeof__(self) self = self_weak_;
//       NSLog(@"1 = %@, 2= %@",self.taskIdentifier, token.taskIdentifier);
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if ([self.taskIdentifier isEqualToString:token.taskIdentifier]) {
//                self.progressView.progressTintColor = [UIColor blueColor];
//                [self.progressView setProgress:downloadProgress.fractionCompleted animated:YES];
//                //            self.progressView.progress = 1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount;
//            }
//        });
//
//    } unzProgress:^(long entryNumber, long total) {
//
//        __strong __typeof__(self) self = self_weak_;
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.stateLabel.text = [NSString stringWithFormat:@"开始解压，解压进度：%lu",entryNumber / total];
//            self.progressView.progressTintColor = [UIColor redColor];
//
//            //            self.progressView.progress = 1.0 * entryNumber / total;
//
//            [self.progressView setProgress:1.0 * entryNumber / total animated:YES];
//        });
//
//    } completed:^(NSURLResponse *response, NSString *filePath, NSError *error) {
//
//        __strong __typeof__(self) self = self_weak_;
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (error) {
//                NSLog(@"error = %@", error);
//                self.stateLabel.text = [NSString stringWithFormat:@"发生错误:%@", error.localizedDescription];
//            }else {
//                NSLog(@"filePath = %@", filePath);
//                self.stateLabel.text = [NSString stringWithFormat:@"解压完成:%@", filePath];
//                self.model.rnAppInfo.bundleURL = [filePath stringByAppendingPathComponent:@"/main.jsbundle"];
//                [[PWPersistenceController sharedInstance] save];
//            }
//        });
//
//    }];
}


- (MSTFileDownloadToken *)updateDownloadForURL:(NSURL *)url
{
    NSString *fileName = [NSString stringWithFormat:@"rn%d%d",self.model.rnAppInfo.mmaId,self.model.rnAppInfo.version];
    __weak __typeof__ (self) self_weak_ = self;
   MSTFileDownloadToken *token = [[MMALoadersManager sharedManager] downloadFileWithURL:url ownFileName:fileName taskIdentifier:self.taskIdentifier progress:^(NSProgress *downloadProgress, MSTFileDownloadToken *tokenTask) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.taskIdentifier isEqualToString:tokenTask.taskIdentifier]) {
                self.progressView.progressTintColor = [UIColor blueColor];
                [self.progressView setProgress:downloadProgress.fractionCompleted animated:YES];
            }
        });
        
    } unzProgress:^(long entryNumber, long total, MSTFileDownloadToken *tokenTask) {
        __strong __typeof__(self) self = self_weak_;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (total == 0 && entryNumber == 0) {
                self.stateLabel.text = @"正在解压...";
            }else {
                self.stateLabel.text = [NSString stringWithFormat:@"解压进度...：%lu/%lu", entryNumber, total];
            }
        });
        
    } completed:^(NSURLResponse *response, NSString *filePath, NSError *error) {
        __strong __typeof__(self) self = self_weak_;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"error = %@", error);
                self.stateLabel.text = [NSString stringWithFormat:@"发生错误:%@", error.localizedDescription];
            }else {
                NSLog(@"filePath = %@", filePath);
                self.stateLabel.text = [NSString stringWithFormat:@"解压完成:%@", filePath];
                self.model.rnAppInfo.bundleURL = [filePath stringByAppendingPathComponent:@"/main.jsbundle"];
                [[PWPersistenceController sharedInstance] save];
                self.model.token = nil;
            }
        });
    }];
    
    return token;
}

@end
