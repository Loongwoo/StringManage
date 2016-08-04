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

@property (weak) IBOutlet NSButton *finishBtn;

- (IBAction)finishAction:(id)sender;
@end

@implementation StringEditViewController

- (instancetype)initWithKey:(NSString*)key
                 identifier:(NSString*)identifier
                      value:(NSString*)value {
    StringEditViewController *vc = [self initWithNibName:@"StringEditViewController"
                                                  bundle:[StringManage sharedPlugin].bundle];
    vc.key = key;
    vc.identifier = identifier;
    vc.value = value;
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.finishBtn setTitle:LocalizedString(@"Finish")];
    self.textView.textColor = [NSColor whiteColor];
    NSString *str = [self.value stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    NSString *str1 = [str stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    [self.textView setString:str1];
}

- (IBAction)finishAction:(id)sender {
    if (self.finishBlock) {
        self.finishBlock();
    }
}
@end
