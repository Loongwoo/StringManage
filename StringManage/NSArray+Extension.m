//
//  NSArray+Extension.m
//  StringManage
//
//  Created by kiwik on 16/3/28.
//  Copyright © 2016年 Kiwik. All rights reserved.
//

#import "NSArray+Extension.h"

@implementation NSArray(Extension)

-(BOOL)isBlank{
    if (self == nil) {
        return YES;
    }
    
    if ([self isKindOfClass:[NSNull class]]) {
        return YES;
    }
    
    if (self.count==0) {
        return YES;
    }
    
    return NO;
}

@end
