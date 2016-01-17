//
//  PathEditViewController
//  XToDo
//
//  Created by shuice on 2014-03-09.
//  Copyright (c) 2014. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface StringCellView : NSTableCellView
@property (nonatomic, strong) NSTextField* titleField;
@property (nonatomic, strong) NSTextField* fileField;
@end

@interface StringInfoViewController : NSViewController <NSTableViewDataSource,NSTableViewDelegate>
- (id)initWithArray:(NSArray*)array;
@end