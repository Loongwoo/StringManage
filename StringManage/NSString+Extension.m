//
//  NSString+Extension.m
//  StringManage
//
//  Created by kiwik on 1/20/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "NSString+Extension.h"
#import <AppKit/AppKit.h>

@implementation NSString(Extension)

-(BOOL)contain:(NSString*)str{
    NSRange range = [self rangeOfString:str options:NSCaseInsensitiveSearch];
    return range.length>0;
}

-(CGRect)sizeWithWidth:(CGFloat)width font:(NSFont*)font{
    NSDictionary *attribute = @{NSFontAttributeName:font};
    return [self boundingRectWithSize:CGSizeMake(width, 2000)
                                        options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                     attributes:attribute
                                        context:nil];
}
@end
