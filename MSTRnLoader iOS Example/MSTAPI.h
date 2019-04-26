//
//  MSTAPI.h
//  MARS
//
//  Created by Fan Li Lin on 2019/3/8.
//  Copyright © 2019 puwang. All rights reserved.
//

#import <Foundation/Foundation.h>

///------------
/// API 接口
///------------

// 登录接口
#define MST_LOGIN_API @"api/user/app/login"

/**
 *  *&* 请求服务器地址(baseUrl) *
 */
FOUNDATION_EXTERN NSString * const MST_ResourceServerKey;

/**
 *  *&* 请求服务器API版本号 *
 */
FOUNDATION_EXTERN NSString * const MST_RequestApiversion;

@interface MSTAPI : NSObject

@end


