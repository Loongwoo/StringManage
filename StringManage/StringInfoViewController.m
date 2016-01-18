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
        self.titleField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 20, frame.size.width - 20, 15)];
        self.titleField.font = [NSFont systemFontOfSize:10];
        self.titleField.textColor = [NSColor lightGrayColor];
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
@property NSMutableArray* array;
@end

@implementation StringInfoViewController

#pragma mark - override
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithArray:(NSArray*)array {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.array = [[NSMutableArray alloc] initWithArray:array];
    }
    return self;
}

-(void)loadView {
    float height = MIN(10+_array.count*35, 360);
    self.view = [[NSView alloc]initWithFrame:NSMakeRect(0,0,600, height)];
    NSScrollView * tableContainer = [[NSScrollView alloc] initWithFrame:NSInsetRect(self.view.bounds, 5, 5)];
    NSTableView * tableView = [[NSTableView alloc] initWithFrame:tableContainer.bounds];
    NSTableColumn * column1 = [[NSTableColumn alloc] initWithIdentifier:@"mycell"];
    [column1 setWidth:tableView.bounds.size.width];
    [tableView addTableColumn:column1];
    
    [tableView setDelegate:self];
    [tableView setDataSource:self];
    [tableView setHeaderView:nil];
    [tableView setGridStyleMask:NSTableViewSolidHorizontalGridLineMask];
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
    StringCellView* cellView = [tableView makeViewWithIdentifier:@"mycell" owner:self];
    if (cellView == nil) {
        cellView = [[StringCellView alloc] initWithFrame:NSMakeRect(0, 0, tableView.bounds.size.width, 35)];
        cellView.identifier = @"mycell";
    }
    StringItem *item = [self.array objectAtIndex:row];
    cellView.titleField.stringValue =[NSString stringWithFormat:@"File : %@", item.filePath];
    cellView.fileField.stringValue = [NSString stringWithFormat:@"Line %ld:%@",item.lineNumber, item.content];
    return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView* tableview = notification.object;
    NSInteger row = [tableview selectedRow];
    StringItem *item = self.array[row];
    [StringModel openItem:item];
}
@end
