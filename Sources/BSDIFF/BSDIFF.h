//
//  BSDIFF.h
//  MSTRnLoader
//
//  Created by Fan Li Lin on 2019/4/25.
//  Copyright © 2019 puwang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BSDIFF : NSObject

+ (BOOL)bsdiffFileAtPath:(NSString *)path
              fromOrigin:(NSString *)origin
           toDestination:(NSString *)destination;

@end


