//
//  BSDIFF.m
//  MSTRnLoader
//
//  Created by Fan Li Lin on 2019/4/25.
//  Copyright © 2019 puwang. All rights reserved.
//

#import "BSDIFF.h"
#include "bsdpatch.h"

@implementation BSDIFF

+ (BOOL)bsdiffFileAtPath:(NSString *)path
              fromOrigin:(NSString *)origin
           toDestination:(NSString *)destination
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return NO;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:origin]) {
        return NO;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:destination]) {
        [[NSFileManager defaultManager] removeItemAtPath:destination error:nil];
    }
    int err = beginPatch([origin UTF8String], [destination UTF8String], [path UTF8String]);
    if (err) {
        return NO;
    }
    return YES;
}

@end
