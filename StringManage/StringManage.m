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
        // reference to plugin's bundle, for resource access
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
    //removeObserver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    // Create menu items, initialize UI, etc.
    // Sample Menu Item:
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
    if (menuItem) {
        [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:LocalizedString(@"StringManage") action:@selector(doMenuAction) keyEquivalent:@""];
        //[actionMenuItem setKeyEquivalentModifierMask:NSAlphaShiftKeyMask | NSControlKeyMask];
        [actionMenuItem setTarget:self];
        [[menuItem submenu] addItem:actionMenuItem];
    }
}

// Sample Action, for menu item:
- (void)doMenuAction
{
    NSString *currentWorkspace = [IAWorkspace currentWorkspacePath];
    if (currentWorkspace) {
//        NSString *currentWorkingDir = [currentWorkspace stringByDeletingLastPathComponent];
//        NSString *path = [currentWorkingDir stringByAppendingPathComponent:@"KiwikTest"];
        NSString *path = [currentWorkspace stringByDeletingPathExtension];
        NSArray *lprojDirectorys = [self lprojDirectoryInPath:path];
        if (lprojDirectorys.count == 0) {
            NSAlert *alert = [[NSAlert alloc]init];
            [alert setMessageText: LocalizedString(@"NoLocalizedFiles")];
            [alert addButtonWithTitle: LocalizedString(@"OK")];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert runModal];
        }
        else {
            [self toggleManage:lprojDirectorys];
        }
    }
}

-(void)toggleManage:(NSArray*)pathArray
{
    NSLog(@"%s %@",__func__, pathArray);
    if (self.windowController.window.isVisible) {
        [self.windowController.window close];
    } else {
        if (self.windowController == nil) {
            StringWindowController* wc = [[StringWindowController alloc] initWithWindowNibName:@"StringWindowController"];
            self.windowController = wc;
        }
        [self.windowController setPathArray:pathArray];
        [self.windowController.window makeKeyAndOrderFront:nil];
    }
}

- (NSArray *)lprojDirectoryInPath:(NSString *)path
{
    NSMutableArray *bundles = [NSMutableArray array];
    
    NSArray* array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for(int i = 0; i<[array count]; i++){
        NSString *fullPath = [path stringByAppendingPathComponent:array[i]];
        NSError *error = nil;
        NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:&error];
        if ([attr[NSFileType] isEqualTo:NSFileTypeDirectory]) {
            if ([@"lproj" isEqualToString:fullPath.pathExtension]) {
                [bundles addObject:fullPath];
            }
        }
    }
    
    /* NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
    NSString *filePath = nil;
    while (filePath = [enumerator nextObject]) {
        if([filePath hasPrefix:@"DerivedData/"]
           || [filePath hasPrefix:@".git/"]
           || [filePath hasPrefix:@"Pods/"])
            continue;
        
        NSString *fullPath = [path stringByAppendingPathComponent:filePath];
        NSError *error = nil;
        NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:&error];
        if ([attr[NSFileType] isEqualTo:NSFileTypeDirectory]) {
            if ([@"lproj" isEqualToString:filePath.pathExtension]) {
                [bundles addObject:fullPath];
            }
        }
    } */
    
    return [NSArray arrayWithArray:bundles];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
