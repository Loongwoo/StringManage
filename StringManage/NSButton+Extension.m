//
//  NSButton+Extension.m
//  StringManage
//
//  Created by kiwik on 1/19/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "NSButton+Extension.h"

@implementation NSButton(Extension)

- (void)setTextColor:(NSColor *)textColor
{
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc]
                                            initWithAttributedString:[self attributedTitle]];
    NSRange range = NSMakeRange(0, [attrTitle length]);
    [attrTitle addAttribute:NSForegroundColorAttributeName value:textColor range:range];
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentCenter;
    [attrTitle addAttribute:NSParagraphStyleAttributeName value:paragraph range:range];
    [attrTitle fixAttributesInRange:range];
    [self setAttributedTitle:attrTitle];
}

@end
