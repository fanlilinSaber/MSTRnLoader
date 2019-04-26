//
//  RNListModel.h
//  MSTRnLoader iOS Example
//
//  Created by Fan Li Lin on 2019/4/23.
//  Copyright © 2019 puwang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSTRnAppModel+CoreDataProperties.h"
#import "MSTFileDownloadToken.h"


@interface RNListModel : NSObject

/*&* <##> */
@property (nonatomic, strong) MSTRnAppModel *rnAppInfo;

/*&* <##> */
@property (nonatomic, strong) MSTFileDownloadToken *token;

/*&* <##> */
@property (nonatomic, copy) NSURL *URL;

@end

