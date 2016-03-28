//
//  StringEditViewController.h
//  StringManage
//
//  Created by kiwik on 2/2/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StringEditViewController : NSViewController

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) void (^finishBlock)(void);

@property (unsafe_unretained) IBOutlet NSTextView *textView;

- (instancetype)initWithKey:(NSString*)key
                 identifier:(NSString*)identifier
                      value:(NSString*)value;

@end
