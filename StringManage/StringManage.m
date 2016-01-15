//
//  StringManage.m
//  StringManage
//
//  Created by kiwik on 1/13/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "StringManage.h"
#import "IAWorkspace.h"
#import "StringWindowController.h"
#import "ProjectSetting.h"

@interface StringManage()

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, strong) StringWindowController* windowController;

@end

@implementation StringManage

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[StringManage alloc] initWithBundle:plugin];
        });
    }
}

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        self.bundle = plugin;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
    if (menuItem) {
        [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:LocalizedString(@"StringManage") action:@selector(doMenuAction) keyEquivalent:@"s"];
        [actionMenuItem setKeyEquivalentModifierMask:NSAlphaShiftKeyMask | NSControlKeyMask];
        [actionMenuItem setTarget:self];
        [[menuItem submenu] addItem:actionMenuItem];
    }
}

- (void)doMenuAction {
    NSString *currentWorkspace = [IAWorkspace currentWorkspacePath];
    if (currentWorkspace) {
        NSString *searchDirectory = [currentWorkspace stringByDeletingPathExtension];
        NSString *projectName = [currentWorkspace lastPathComponent];
        
        [ProjectSetting shareInstance].projectName = projectName;
        NSString *saveTag = [[ProjectSetting shareInstance] settingName];
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:saveTag];
        if(dict) {
            [ProjectSetting shareInstance].searchDirectory = dict[kSearchDirectory];
            [ProjectSetting shareInstance].searchTableName = dict[kSearchTableName];
        }else{
            [ProjectSetting shareInstance].searchDirectory = searchDirectory;
            [ProjectSetting shareInstance].searchTableName = @"Localizable.strings";
        }
        
        if (self.windowController.window.isVisible) {
            [self.windowController.window close];
        } else {
            if (self.windowController == nil) {
                StringWindowController* wc = [[StringWindowController alloc] initWithWindowNibName:@"StringWindowController"];
                self.windowController = wc;
            }
            [self.windowController.window makeKeyAndOrderFront:nil];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
