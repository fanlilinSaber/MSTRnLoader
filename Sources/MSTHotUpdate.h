//
//  MSTHotUpdate.h
//  MARS
//
//  Created by Fan Li Lin on 2019/4/16.
//  Copyright © 2019 puwang. All rights reserved.
//

#if __has_include(<React/RCTEventEmitter.h>)
#import <React/RCTEventEmitter.h>
#else
#import "React/RCTEventEmitter.h"
#endif

@interface MSTHotUpdate : RCTEventEmitter

+ (NSURL *)bundleURL;

@end

