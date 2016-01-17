//
//  StringWindowController.h
//  StringManage
//
//  Created by kiwik on 1/13/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StringWindowController : NSWindowController

- (void)setSearchRootDir:(NSString*)searchRootDir projectName:(NSString*)projectName;

- (IBAction)refresh:(id)sender;

@end
