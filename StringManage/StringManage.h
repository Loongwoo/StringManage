//
//  StringManage.h
//  StringManage
//
//  Created by kiwik on 1/13/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import <AppKit/AppKit.h>

#define LocalizedString(key) [[StringManage sharedPlugin].bundle localizedStringForKey:(key) value:(key) table:nil]

@class StringManage;
static StringManage *sharedPlugin;
@interface StringManage : NSObject
+ (instancetype)sharedPlugin;
@property (nonatomic, strong, readonly) NSBundle* bundle;
@end