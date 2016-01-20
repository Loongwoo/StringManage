//
//  NSButton+Extension.h
//  StringManage
//
//  Created by kiwik on 1/19/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSButton(Extension)
- (void)setTitle:(NSString *)title textColor:(NSColor *)textColor;
- (void)setAlternateTitle:(NSString *)alternateTitle textColor:(NSColor *)textColor;
@end
