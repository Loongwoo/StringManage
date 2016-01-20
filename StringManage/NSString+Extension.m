//
//  NSString+Extension.m
//  StringManage
//
//  Created by kiwik on 1/20/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "NSString+Extension.h"

@implementation NSString(Extension)

-(BOOL)contain:(NSString*)str{
    NSRange range = [self rangeOfString:str options:NSCaseInsensitiveSearch];
    return range.length>0;
}

@end
