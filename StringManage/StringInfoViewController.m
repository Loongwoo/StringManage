//
//  PathEditViewController
//  XToDo
//
//  Created by kiwik on 1/16/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "StringInfoViewController.h"
#import "StringModel.h"
#import "StringManage.h"

@implementation StringCellView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSTextField *titleField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 20, frame.size.width, 15)];
        titleField.font = [NSFont systemFontOfSize:10];
        titleField.textColor = [NSColor darkGrayColor];
        [titleField setAutoresizingMask:NSViewWidthSizable];
        [[titleField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [titleField setBezeled:NO];
        [titleField setDrawsBackground:NO];
        [titleField setEditable:NO];
        [titleField setSelectable:NO];
        [self addSubview:titleField];
        self.titleField = titleField;
        
        NSTextField *fileField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, 20)];
        fileField.font = [NSFont systemFontOfSize:12];
        fileField.textColor = [NSColor colorWithWhite:0.2 alpha:0.9];
        [fileField setAutoresizingMask:NSViewWidthSizable];
        [[fileField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [fileField setBezeled:NO];
        [fileField setDrawsBackground:NO];
        [fileField setEditable:NO];
        [fileField setSelectable:NO];
        [self addSubview:fileField];
        self.fileField = fileField;
    }
    return self;
}
@end

@interface StringInfoViewController ()
@property NSMutableArray* array;
@end

@implementation StringInfoViewController

#pragma mark - override
- (void)dealloc {
}

- (instancetype)initWithArray:(NSArray*)array {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.array = [[NSMutableArray alloc] initWithArray:array];
    }
    return self;
}

-(void)loadView {
    float height = MIN(10+_array.count*37, 360);
    self.view = [[NSView alloc]initWithFrame:NSMakeRect(0,0,600, height)];
    NSScrollView * tableContainer = [[NSScrollView alloc] initWithFrame:NSInsetRect(self.view.bounds, 5, 5)];
    NSTableView * tableView = [[NSTableView alloc] initWithFrame:tableContainer.bounds];
    NSTableColumn * column1 = [[NSTableColumn alloc] initWithIdentifier:@"mycolumn"];
    [column1 setWidth:tableView.bounds.size.width];
    [tableView addTableColumn:column1];
    [tableView setDelegate:self];
    [tableView setDataSource:self];
    [tableView setHeaderView:nil];
    [tableView setGridStyleMask:NSTableViewSolidHorizontalGridLineMask];
    [tableView setUsesAlternatingRowBackgroundColors:YES];
    [tableView reloadData];
    [tableContainer setDocumentView:tableView];
    [tableContainer setHasVerticalScroller:YES];
    [self.view addSubview:tableContainer];
}

#pragma mark - NSTableView
- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView {
    return [self.array count];
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 35.0f;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    static NSString *identifier = @"mycell";
    StringCellView* cellView = [tableView makeViewWithIdentifier:identifier owner:self];
    if (cellView == nil) {
        cellView = [[StringCellView alloc] initWithFrame:NSMakeRect(0, 0, tableView.bounds.size.width, 35)];
        cellView.identifier = identifier;
    }
    StringItem *item = [self.array objectAtIndex:row];
    cellView.titleField.stringValue =[NSString stringWithFormat:@"File : %@", item.filePath];
    cellView.fileField.stringValue = [NSString stringWithFormat:@"Line %ld:%@",item.lineNumber, item.content];
    return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView* tableview = notification.object;
    NSInteger row = [tableview selectedRow];
    if(row<0 || row>=self.array.count)
        return;
    StringItem *item = self.array[row];
    [StringModel openItem:item];
    [tableview deselectRow:row];
}
@end
