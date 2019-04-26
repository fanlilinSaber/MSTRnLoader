//
//  RNListCell.h
//  MSTRnLoader iOS Example
//
//  Created by Fan Li Lin on 2019/4/23.
//  Copyright © 2019 puwang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RNListModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RNListCell : UITableViewCell
/*&* <##> */
@property (nonatomic, strong) UILabel *nameLabel;
/*&* <##> */
@property (nonatomic, strong) UILabel *versionLabel;
/*&* <##> */
@property (nonatomic, strong) UILabel *stateLabel;

@property (nonatomic, strong) UIProgressView *progressView;

/*&* <##> */
@property (nonatomic, copy) NSURL *URL;


- (void)startDownloadForURL:(NSURL *)url;

/*&* <##> */
@property (nonatomic, strong) MSTFileDownloadToken *token;

/*&* <##> */
@property (nonatomic, strong) RNListModel *model;
/*&* <##> */
@property (nonatomic, copy) NSString *taskIdentifier;

@end

NS_ASSUME_NONNULL_END
