//
//  StringWindowController.m
//  StringManage
//
//  Created by kiwik on 1/13/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "StringWindowController.h"
#import "StringModel.h"
#import "StringManage.h"
#import "PreferencesWindowController.h"
#import "StringSetting.h"
#import "StringInfoViewController.h"

#define KEY @"key"
#define REMOVE @"remove"
#define kInfo @"info"

@interface StringWindowController()<NSTableViewDelegate,NSTableViewDataSource,NSTextFieldDelegate,NSSearchFieldDelegate>

@property (nonatomic, strong)IBOutlet NSTableView *tableview;
@property (weak) IBOutlet NSButton *refreshBtn;
@property (weak) IBOutlet NSButton *saveBtn;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *recordLabel;
@property (weak) IBOutlet NSSearchField *searchField;

@property (nonatomic, strong) NSMutableArray *stringArray;
@property (nonatomic, strong) NSMutableArray *keyArray;
@property (nonatomic, strong) NSMutableArray *actionArray;
@property () PreferencesWindowController* prefsController;
@property (nonatomic, strong) NSArray *showArray;
@property (nonatomic, copy) NSString* projectPath;
@property (nonatomic, copy) NSString* projectName;
@property (nonatomic, copy) NSDictionary* infoDict;

- (IBAction)addAction:(id)sender;
- (IBAction)saveAction:(id)sender;
- (IBAction)searchAnswer:(id)sender;

@end

@implementation StringWindowController

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    self.prefsController = [[PreferencesWindowController alloc] init];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.actionArray=[[NSMutableArray alloc]init];
    self.stringArray = [[NSMutableArray alloc]init];
    self.keyArray = [[NSMutableArray alloc]init];
    
    self.window.level = NSFloatingWindowLevel;
    self.window.hidesOnDeactivate = YES;
    [self.window setTitle:LocalizedString(@"StringManage")];
    
    self.tableview.delegate=self;
    self.tableview.dataSource = self;
    self.tableview.doubleAction = @selector(doubleClicked:);
    [self.window makeFirstResponder:self.tableview];
    
    [self.searchField setPlaceholderString:LocalizedString(@"Search")];
    [self.saveBtn setTitle:LocalizedString(@"Save")];
    [self.saveBtn setEnabled:NO];
    [self.refreshBtn setTitle:LocalizedString(@"Refresh")];
    
    self.progressIndicator.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endEditingAction:) name:NSControlTextDidEndEditingNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_onNotifyProjectSettingChanged:)
                                                 name:kNotifyProjectSettingChanged
                                               object:nil];
}

- (void)setSearchRootDir:(NSString*)searchRootDir projectName:(NSString*)projectName {
    self.projectPath = searchRootDir;
    self.projectName = projectName;
    self.prefsController.projectPath = searchRootDir;
    self.prefsController.projectName = projectName;
}

- (void)_onNotifyProjectSettingChanged:(NSNotification*)notification {
    [self refresh:nil];
}

- (IBAction)openAbout:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/Loongwoo/StringManage"]];
}

- (IBAction)showPreferencesPanel:(id)sender {
    [self.prefsController loadWindow];
    
    NSRect windowFrame = [[self window] frame], prefsFrame = [[self.prefsController window] frame];
    prefsFrame.origin = NSMakePoint(windowFrame.origin.x + (windowFrame.size.width - prefsFrame.size.width) / 2.0,
                                    NSMaxY(windowFrame) - NSHeight(prefsFrame) - 20.0);
    
    [[self.prefsController window] setFrame:prefsFrame display:NO];
    [self.prefsController showWindow:sender];
}

- (IBAction)refresh:(id)sender {
    
    [self.progressIndicator setHidden:NO];
    [self.progressIndicator startAnimation:nil];
    [self.refreshBtn setEnabled:NO];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        StringSetting *projectSetting = [StringModel projectSettingByProjectName:self.projectName];
        NSArray *lprojDirectorys = [StringModel lprojDirectoriesWithProjectSetting:projectSetting project:self.projectPath];
            if (lprojDirectorys.count == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSAlert *alert = [[NSAlert alloc]init];
                    [alert setMessageText: LocalizedString(@"NoLocalizedFiles")];
                    [alert addButtonWithTitle: LocalizedString(@"OK")];
                    [alert setAlertStyle:NSWarningAlertStyle];
                    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                        [self.progressIndicator setHidden:YES];
                        [self.progressIndicator stopAnimation:nil];
                        [self.refreshBtn setEnabled:YES];
                    }];
                });
            } else {
                [_stringArray removeAllObjects];
                [_keyArray removeAllObjects];
                
                NSMutableSet *keySet = [[NSMutableSet alloc]init];
                for (NSString *path in lprojDirectorys) {
                    StringModel *model = [[StringModel alloc]initWithPath:path projectSetting:projectSetting];
                    [_stringArray addObject:model];
                    NSArray *keys = model.stringDictionary.allKeys;
                    NSSet *set = [NSSet setWithArray:keys];
                    [keySet unionSet:set];
                }
                
                NSArray *tmp = [[NSArray alloc]initWithArray:keySet.allObjects];
                NSArray *sortedArray = [tmp sortedArrayUsingComparator:^NSComparisonResult(NSString * obj1, NSString * obj2) {
                    return [obj1 compare:obj2 options:NSNumericSearch];
                }];
                [_keyArray addObjectsFromArray:sortedArray];
                
                self.infoDict = [StringModel findItemsWithProjectPath:projectSetting projectPath:self.projectPath findStrings:_keyArray];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self refreshTableView];
                    
                    [self.progressIndicator setHidden:YES];
                    [self.progressIndicator startAnimation:nil];
                    [self.refreshBtn setEnabled:YES];
                });
            }
    });
}

-(void)refreshTableView {
    NSArray *columns = [[NSArray alloc]initWithArray:self.tableview.tableColumns];
    [columns enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSTableColumn *column = (NSTableColumn*)obj;
        [self.tableview removeTableColumn:column];
    }];
    
    float width = self.tableview.bounds.size.width;
    float columnWidth = (width - 160.0)/(_stringArray.count+1);
    
    NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:KEY];
    [column setTitle:KEY];
    [column setWidth:columnWidth];
    [self.tableview addTableColumn:column];
    
    for (StringModel *model in _stringArray) {
        NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:model.identifier];
        [column setTitle:model.identifier];
        [column setWidth:columnWidth];
        [self.tableview addTableColumn:column];
    }
    
    NSTableColumn * lastcolumn = [[NSTableColumn alloc] initWithIdentifier:REMOVE];
    [lastcolumn setTitle:@""];
    [lastcolumn setWidth:80];
    [lastcolumn setMinWidth:60];
    [lastcolumn setMaxWidth:100];
    [self.tableview addTableColumn:lastcolumn];
    NSTableColumn * infocolumn = [[NSTableColumn alloc] initWithIdentifier:kInfo];
    [infocolumn setTitle:@""];
    [infocolumn setWidth:80];
    [infocolumn setMinWidth:60];
    [infocolumn setMaxWidth:100];
    [self.tableview addTableColumn:infocolumn];
    
    [self searchAnswer:nil];
}

- (IBAction)searchAnswer:(id)sender {
    NSString *searchString = _searchField.stringValue;
    if(searchString.length==0){
        self.showArray = _keyArray;
    }else{
        NSMutableArray *tmp = [NSMutableArray array];
        for (NSString *key in _keyArray) {
            NSRange range = [key rangeOfString:searchString options:NSCaseInsensitiveSearch];
            if(range.length>0){
                [tmp addObject:key];
            }else{
                for (StringModel *model in _stringArray) {
                    NSString *value = [model.stringDictionary objectForKey:key];
                    NSRange range1 = [value rangeOfString:searchString options:NSCaseInsensitiveSearch];
                    if(range1.length>0){
                        [tmp addObject:key];
                        break;
                    }
                }
            }
        }
        self.showArray = tmp;
    }
    self.recordLabel.stringValue = [NSString stringWithFormat:LocalizedString(@"RecordNumMsg"),self.showArray.count];
    [self.tableview reloadData];
}

- (IBAction)addAction:(id)sender {
    NSAlert *alert = [[NSAlert alloc]init];
    [alert setMessageText: LocalizedString(@"InputKeyMsg")];
    [alert addButtonWithTitle: LocalizedString(@"OK")];
    [alert addButtonWithTitle:LocalizedString(@"Cancel")];
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [alert setAccessoryView:input];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if(returnCode == NSAlertFirstButtonReturn) {
            [self dealWithInput:input.stringValue];
        }
    }];
}

-(void)dealWithInput:(NSString*)input
{
    if(input.length==0)
        return;
    if([_keyArray containsObject:input]) {
        NSAlert *alert = [[NSAlert alloc]init];
        [alert setMessageText: LocalizedString(@"InputIsExist")];
        [alert addButtonWithTitle: LocalizedString(@"OK")];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            
        }];
    } else {
        [_keyArray addObject:input];
        [self.searchField setStringValue:@""];
        [self searchAnswer:nil];
        [self.tableview scrollRowToVisible:_keyArray.count-1];
    }
}

- (IBAction)saveAction:(id)sender {
    [self.window makeFirstResponder:nil];
    if(_actionArray.count==0)
        return;
    for (StringModel *model in _stringArray) {
        [model doAction:_actionArray];
    }
    [_actionArray removeAllObjects];
    [self.saveBtn setEnabled:NO];
    [self refresh:nil];
}

-(void)doubleClicked:(id)sender {
    NSInteger column = _tableview.clickedColumn;
    NSInteger row = _tableview.clickedRow;
    if(column<0 || column >= self.tableview.tableColumns.count)
        return;
    if(row < 0 || row >= _keyArray.count)
        return;
    
    [_tableview editColumn:column row:row withEvent:nil select:YES];
}

-(void)endEditingAction:(NSNotification*)notification {
    NSTextField *textField = notification.object;
    NSString *identifier = textField.identifier;
    if(identifier.length==0 || textField.tag >= _showArray.count)
        return;
    
    NSString *key = _showArray[textField.tag];
    NSString *oldValue = [self titleWithKey:key identifier:identifier];
    NSString *newValue = textField.stringValue;
    if([oldValue isEqualToString:newValue])
        return;
    
    if([identifier isEqualToString:KEY]) {
        if([_keyArray containsObject:newValue] || newValue.length==0) {
            //TODO ??? key必须唯一
            [self searchAnswer:nil];
        } else {
            for (StringModel *model in _stringArray) {
                NSString *value = [self titleWithKey:key identifier:model.identifier];
                ActionModel *action = [[ActionModel alloc]init];
                action.actionType = ActionTypeAdd;
                action.identifier = model.identifier;
                action.key = newValue;
                action.value = value;
                [_actionArray addObject:action];
                [model.stringDictionary setObject:value forKey:newValue];
                
                ActionModel *action1 = [[ActionModel alloc]init];
                action1.actionType = ActionTypeRemove;
                action1.identifier = model.identifier;
                action1.key = oldValue;
                action1.value = value;
                [_actionArray addObject:action1];
                [model.stringDictionary removeObjectForKey:key];
            }
            NSInteger index = [_keyArray indexOfObject:oldValue];
            [_keyArray replaceObjectAtIndex:index withObject:newValue];
            
            [self.saveBtn setEnabled:YES];
        }
    } else {
        for (StringModel *model in _stringArray) {
            if([model.identifier isEqualToString:identifier]) {
                ActionModel *action = [[ActionModel alloc]init];
                action.actionType = ActionTypeAdd;
                action.identifier = model.identifier;
                action.key = key;
                action.value = newValue;
                [_actionArray addObject:action];
                
                [model.stringDictionary setObject:newValue forKey:key];
                
                [self.saveBtn setEnabled:YES];
            }
        }
    }
}

-(void)removeAction:(id)sender {
    NSButton *button = (NSButton*)sender;
    NSString *key=button.identifier;
    
    NSAlert *alert = [[NSAlert alloc]init];
    NSString *msg = [NSString stringWithFormat:LocalizedString(@"RemoveConfirm"),key];
    [alert setMessageText: msg];
    [alert addButtonWithTitle: LocalizedString(@"OK")];
    [alert addButtonWithTitle:LocalizedString(@"Cancel")];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if(returnCode == NSAlertFirstButtonReturn) {
            for (StringModel *model in _stringArray) {
                ActionModel *action = [[ActionModel alloc]init];
                action.actionType = ActionTypeRemove;
                action.identifier = model.identifier;
                action.key = key;
                [_actionArray addObject:action];
                
                [model.stringDictionary removeObjectForKey:key];
                [self.saveBtn setEnabled:YES];
            }
            [_keyArray removeObject:key];
            
            [self.tableview beginUpdates];
            [self.tableview removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:button.tag] withAnimation:NSTableViewAnimationEffectFade];
            [self.tableview endUpdates];
            
            [self searchAnswer:nil];
        }
    }];
}

-(NSString*)titleWithKey:(NSString*)key identifier:(NSString*)identifier {
    if([identifier isEqualToString:KEY]) {
        return key;
    } else  {
        for (StringModel *model in _stringArray) {
            if ([identifier isEqualToString:model.identifier])  {
                NSString *result = model.stringDictionary[key];
                return result.length ? result : @"";
            }
        }
    }
    return @"";
}

-(void)infoAction:(id)sender
{
    NSButton *button = (NSButton*)sender;
    NSString *key=button.identifier;
    if(self.infoDict && key.length>0)
    {
        NSArray *infos = self.infoDict[key];
        NSLog(@"infos %@",infos);
        NSPopover* popover = [[NSPopover alloc] init];
        popover.delegate = self;
        popover.behavior = NSPopoverBehaviorTransient;
        StringInfoViewController* viewController = [[StringInfoViewController alloc] initWithArray:infos];
        [popover setContentViewController:viewController];
        [popover showRelativeToRect:CGRectMake(0, 0, 400, 400) ofView:sender preferredEdge:NSMinXEdge];
    }
}

#pragma mark -
#pragma mark - NSTableViewDelegate & NSTableViewDataSource
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(nullable NSTableColumn *)tableColumn {
    return NO;
}

-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return ![tableColumn.identifier isEqualToString:REMOVE];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.showArray.count;
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 20.0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if(row>=self.showArray.count)
        return nil;
    NSString *identifier=[tableColumn identifier];
    NSString *key = self.showArray[row];
    if([identifier isEqualToString:@"remove"]){
        NSButton *aView = [tableView makeViewWithIdentifier:identifier owner:self];
        if(!aView) {
            aView = [[NSButton alloc]initWithFrame:NSZeroRect];
            [aView setTitle:LocalizedString(@"Remove")];
            [aView setAction:@selector(removeAction:)];
            [aView setTarget:self];
            [aView setState:1];
        }
        [aView setTag:row];
        [aView setIdentifier:key];
        return aView;
    } if([identifier isEqualToString:@"info"]){
        NSButton *aView = [tableView makeViewWithIdentifier:identifier owner:self];
        if(!aView) {
            aView = [[NSButton alloc]initWithFrame:NSZeroRect];
            [aView setTitle:LocalizedString(@"Info")];
            [aView setAction:@selector(infoAction:)];
            [aView setTarget:self];
            [aView setState:1];
        }
        [aView setTag:row];
        [aView setIdentifier:key];
        return aView;
    }else {
        NSString *title = [self titleWithKey:key identifier:identifier];
        NSTextField *aView = [tableView makeViewWithIdentifier:@"MYCell" owner:self];
        if(!aView) {
            aView = [[NSTextField alloc]initWithFrame:NSZeroRect];
            [aView setTextColor:[NSColor blackColor]];
            [aView setTarget:self];
        }
        [aView setTag:row];
        [aView setIdentifier:identifier];
        [aView setPlaceholderString:title];
        [aView setStringValue:title];
        return aView;
    }
}
#pragma mark - NSTableViewDelegate & NSTableViewDataSource
#pragma mark -
@end
