//
//  XToDoPreferencesWindowController.h
//  XToDo
//
//  Created by kiwik on 1/16/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesWindowController : NSWindowController<NSPopoverDelegate, NSTextFieldDelegate>

@property (nonatomic, copy) NSString* projectPath;
@property (nonatomic, copy) NSString* projectName;

@end
