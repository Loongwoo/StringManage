//
//  PathEditViewController
//  XToDo
//
//  Created by shuice on 2014-03-09.
//  Copyright (c) 2014. All rights reserved.
//

#import "StringInfoViewController.h"
#import "StringModel.h"
#import "StringManage.h"

@implementation StringCellView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 20, frame.size.width - 20, 15)];
        self.titleField.font = [NSFont systemFontOfSize:10];
        self.titleField.textColor = [NSColor darkGrayColor];
        [self.titleField setAutoresizingMask:NSViewWidthSizable];
        [[self.titleField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [self addSubview:self.titleField];
        self.titleField = self.titleField;
        
        self.fileField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 0, frame.size.width - 20, 20)];
        self.fileField.font = [NSFont systemFontOfSize:12];
        self.fileField.textColor = [NSColor darkGrayColor];
        [self.fileField setAutoresizingMask:NSViewWidthSizable];
        [[self.fileField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [self addSubview:self.fileField];
        self.fileField = self.fileField;
        
        [self.titleField setBezeled:NO];
        [self.titleField setDrawsBackground:NO];
        [self.titleField setEditable:NO];
        [self.titleField setSelectable:NO];
        
        [self.fileField setBezeled:NO];
        [self.fileField setDrawsBackground:NO];
        [self.fileField setEditable:NO];
        [self.fileField setSelectable:NO];
    }
    return self;
}
@end

@interface StringInfoViewController ()
@property IBOutlet NSTableView* tableView;
@property NSMutableArray* array;
@end

@implementation StringInfoViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - override
- (id)initWithArray:(NSArray*)array {
    StringInfoViewController* pathEditViewController = [self initWithNibName:@"StringInfoViewController"
                                                                    bundle:[StringManage sharedPlugin].bundle];
    self.array = [[NSMutableArray alloc] initWithArray:array];
    return pathEditViewController;
}

- (void)awakeFromNib {
    self.tableView.dataSource = self;
    self.tableView.delegate=self;
    [self.tableView reloadData];
}

#pragma mark - NSTableView
- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView {
    return [self.array count];
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 35.0f;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    StringCellView* cellView = [tableView makeViewWithIdentifier:@"mycell" owner:self];
    if (cellView == nil) {
        cellView = [[StringCellView alloc] initWithFrame:NSMakeRect(0, 0, tableView.bounds.size.width, 35)];
        cellView.identifier = @"mycell";
    }
    StringItem *item = [self.array objectAtIndex:row];
    cellView.titleField.stringValue =[NSString stringWithFormat:@"Line %ld : %@",item.lineNumber, item.filePath];
    cellView.fileField.stringValue = item.content;
    return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView* tableview = notification.object;
    NSInteger row = [tableview selectedRow];
    StringItem *item = self.array[row];
    [StringModel openItem:item];
}
@end
