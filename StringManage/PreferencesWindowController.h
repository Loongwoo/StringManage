//
//  XToDoPreferencesWindowController.h
//  XToDo
//
//  Created by Georg Kaindl on 25/01/14.
//  Copyright (c) 2014 Plumn LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesWindowController : NSWindowController<NSPopoverDelegate>

@property (nonatomic, copy) NSString* projectPath;
@property (nonatomic, copy) NSString* projectName;

@end
