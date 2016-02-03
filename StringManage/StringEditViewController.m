//
//  StringEditViewController.m
//  StringManage
//
//  Created by kiwik on 2/2/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "StringEditViewController.h"
#import "StringModel.h"
#import "StringManage.h"

@interface StringEditViewController ()<NSTextViewDelegate>

@end

@implementation StringEditViewController

- (instancetype)initWithKey:(NSString*)key
                 identifier:(NSString*)identifier
                      value:(NSString*)value{
    StringEditViewController *vc = [self initWithNibName:@"StringEditViewController"
                                                  bundle:[StringManage sharedPlugin].bundle];
    vc.key = key;
    vc.identifier = identifier;
    vc.value = value;
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textView.textColor = [NSColor whiteColor];
    NSString *str = [self.value stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    [self.textView setString:str];
}
@end
