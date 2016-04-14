//
//  StringInfoViewController
//  XToDo
//
//  Created by kiwik on 1/16/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface StringCellView : NSTableCellView
@property (nonatomic, strong) NSTextField* titleField;
@property (nonatomic, strong) NSTextField* fileField;
@end

@interface StringInfoViewController : NSViewController <NSTableViewDataSource,NSTableViewDelegate>
@property (nonatomic, copy) NSString *key;
- (id)initWithArray:(NSArray*)array;
@end