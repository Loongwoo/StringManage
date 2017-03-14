//
//  StringManage.m
//  StringManage
//
//  Created by kiwik on 1/13/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "StringManage.h"
#import "StringWindowController.h"
#import "StringModel.h"

static dispatch_once_t onceToken;

@interface StringManage()
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, strong) StringWindowController* windowController;
@end

@implementation StringManage

+ (void)pluginDidLoad:(NSBundle *)plugin {
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[StringManage alloc] initWithBundle:plugin];
        });
    }
}

+ (instancetype)sharedPlugin {
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle mainBundle];
        sharedPlugin = [[StringManage alloc] initWithBundle:bundle];
    });
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin {
    if (self = [super init]) {
        self.bundle = plugin;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti {
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
    NSString* filePath = [[StringModel currentWorkspaceDocument].workspace.representingFilePath.fileURL path];
    if (filePath) {
        if (self.windowController.window.isVisible) {
            [self.windowController.window close];
        } else {
            if (self.windowController == nil) {
                self.windowController = [[StringWindowController alloc] init];
            }
            NSString* projectDir = [filePath stringByDeletingLastPathComponent];
            NSString *projectName = [filePath lastPathComponent];
            [self.windowController.window makeKeyAndOrderFront:nil];
            [self.windowController setSearchRootDir:projectDir projectName:projectName];
            [self.windowController refresh:nil];
        }
    }
}

@end
