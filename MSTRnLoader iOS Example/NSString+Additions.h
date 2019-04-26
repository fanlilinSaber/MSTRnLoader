//
//  NSString+Additions.h
//  YiYuanYunGou
//
//  Created by 范李林 on 16/9/1.
//  Copyright © 2016年 LC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

@interface NSString (Additions)

#pragma mark - java api
/*&* 匹配是否相同 */
- (NSUInteger) compareTo:(NSString *)comp;
/*&* 匹配忽略大小写 */
- (NSUInteger) compareToIgnoreCase:(NSString*)comp;
/*&* 是否包含子str */
- (bool)contains:(NSString *)substring;
- (bool)endsWith: (NSString *)substring;
- (bool)startsWith: (NSString *)substring;
/*&* 查询子str 所在self位置 */
- (NSUInteger)indexOf:(NSString*) substring;
/*&* 根据子str的index 查询所在self 中的位置 */
- (NSUInteger)indexOf:(NSString *)substring startingFrom:(NSUInteger)index;
/*&* 从后面向前面查询 */
- (NSUInteger)lastIndexOf:(NSString *)substring;
/*&* 从后面向前面查询 */
- (NSUInteger)lastIndexOf:(NSString *)substring startingFrom:(NSUInteger)index;
/*&* 根据from  to  返回str */
- (NSString *)substringFromIndex:(NSUInteger)from toIndex:(NSUInteger)to;
/*&* 修剪特殊符号 空白 and 换行 */
- (NSString *)trim;
/*&* 修建特殊符号 @／：；（）¥「」＂、[]{}#%-*+=_\\|~＜＞$€^•'@#$%^&*()_+'\" */
- (NSString *)removeSpecialCharacter;
/*&* 分割成数组 */
- (NSArray *)split:(NSString *) token;
- (NSArray *)split:(NSString *) token limit:(NSUInteger) maxResults;
/*&* 替换 */
- (NSString *)replace: (NSString*) target withString: (NSString*) replacement;

/*&* 返回size */
- (CGSize)sizeWithConstrainedToWidth:(float)width fromFont:(UIFont *)font1 lineSpace:(float)lineSpace;
- (CGSize)sizeWithConstrainedToSize:(CGSize)size fromFont:(UIFont *)font1 lineSpace:(float)lineSpace;
/*&* NSString  绘制*/
- (void)drawInContext:(CGContextRef)context withPosition:(CGPoint)p andFont:(UIFont *)font andTextColor:(UIColor *)color andHeight:(float)height andWidth:(float)width andLenghtHeight:(float)LenghtHeight;

- (void)drawInContext:(CGContextRef)context withPosition:(CGPoint)p andFont:(UIFont *)font andTextColor:(UIColor *)color andHeight:(float)height;

/*&* 返回size*/
- (CGSize)sizeWithFont:(UIFont *)font;
/**
 *  根据字体大小  最大宽度
 *
 *  @param font 字体大小
 *  @param maxW 最大宽度
 *
 *  @return size
 */
- (CGSize)sizeWithFont:(UIFont *)font andMaxW:(CGFloat)maxW;
- (CGSize)getSizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size;
/*&* 是否是空值 */
+ (BOOL)isBlankString:(NSString *)string;

/**
 Returns a lowercase NSString for md5 hash.
 */
- (NSString *)md5String;
/**
 Returns a 32 String.
 */
+ (NSString *)random32String;

@end
