//
//  NSString+Pinyin.h
//  SocialFusion
//
//  Created by Blue Bitch on 11-9-12.
//  Copyright 2011年 Tongji Apple Club. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(Pinyin)

- (NSString *)pinyinFirstLetterArray;
- (NSString *)pinyinFirstLetterAtIndex:(NSUInteger)i;

@end
