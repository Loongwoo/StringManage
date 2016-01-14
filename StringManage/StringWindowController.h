//
//  StringWindowController.h
//  StringManage
//
//  Created by kiwik on 1/13/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StringWindowController : NSWindowController

@property (nonatomic, strong) NSArray *pathArray;

- (IBAction)refresh:(id)sender;

@end
