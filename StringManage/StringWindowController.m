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

@interface StringWindowController()

@property (nonatomic, strong)IBOutlet NSTableView *tableview;
@property (weak) IBOutlet NSButton *refreshBtn;
@property (weak) IBOutlet NSButton *saveBtn;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *recordLabel;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSButton *addBtn;
@property (weak) IBOutlet NSButton *CheckBtn;
@property (weak) IBOutlet NSProgressIndicator *checkIndicator;

@property (nonatomic, strong) NSMutableArray *stringArray;
@property (nonatomic, strong) NSMutableArray *keyArray;
@property (nonatomic, strong) NSMutableArray *actionArray;
@property () PreferencesWindowController* prefsController;
@property (nonatomic, strong) NSArray *showArray;
@property (nonatomic, copy) NSString* projectPath;
@property (nonatomic, copy) NSString* projectName;
@property (nonatomic, strong) NSMutableDictionary* infoDict;
@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, copy) NSArray *rawKeyArray;
@property (nonatomic, strong) NSMutableDictionary* keyDict;
@property (nonatomic, assign) BOOL isChecking;

- (IBAction)addAction:(id)sender;
- (IBAction)saveAction:(id)sender;
- (IBAction)searchAnswer:(id)sender;
- (IBAction)checkAction:(id)sender;
@end

@implementation StringWindowController

#pragma mark - override
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
    self.infoDict = [[NSMutableDictionary alloc]init];
    self.keyDict = [[NSMutableDictionary alloc]init];
    
    self.window.level = NSFloatingWindowLevel;
    self.window.hidesOnDeactivate = YES;
    [self.window setTitle:LocalizedString(@"StringManage")];
    
    self.tableview.delegate=self;
    self.tableview.dataSource = self;
    self.tableview.action = @selector(cellClicked:);//点击编辑
    self.tableview.doubleAction = @selector(doubleAction:);//双击撤销修改
    [self.window makeFirstResponder:self.tableview];
    
    [self.searchField setPlaceholderString:LocalizedString(@"Search")];
    [self.saveBtn setTitle:LocalizedString(@"Save")];
    [self.refreshBtn setTitle:LocalizedString(@"Refresh")];
    [self.CheckBtn setTitle:LocalizedString(@"Check")];
    [self.checkIndicator setHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endEditingAction:) name:NSControlTextDidEndEditingNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_onNotifyProjectSettingChanged:)  name:kNotifyProjectSettingChanged object:nil];
}

#pragma mark - Private
- (void)setSearchRootDir:(NSString*)searchRootDir projectName:(NSString*)projectName {
    self.projectPath = searchRootDir;
    self.projectName = projectName;
    self.prefsController.projectPath = searchRootDir;
    self.prefsController.projectName = projectName;
}

-(void)setIsRefreshing:(BOOL)isRefreshing {
    _isRefreshing = isRefreshing;
    if(isRefreshing) {
        [self.progressIndicator setHidden:NO];
        [self.progressIndicator startAnimation:nil];
        [self.refreshBtn setEnabled:NO];
        [self.addBtn setEnabled:NO];
    }else{
        [self.progressIndicator setHidden:YES];
        [self.progressIndicator stopAnimation:nil];
        [self.refreshBtn setEnabled:YES];
        [self.addBtn setEnabled:YES];
    }
}

-(void)setIsChecking:(BOOL)isChecking{
    _isChecking = isChecking;
    if(isChecking){
        [self.refreshBtn setEnabled:NO];
        [self.addBtn setEnabled:NO];
        [self.CheckBtn setEnabled:NO];
        [self.checkIndicator setHidden:NO];
        [self.checkIndicator startAnimation:nil];
    }else{
        [self.refreshBtn setEnabled:YES];
        [self.addBtn setEnabled:YES];
        [self.CheckBtn setEnabled:YES];
        [self.checkIndicator setHidden:YES];
        [self.checkIndicator stopAnimation:nil];
    }
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
    [lastcolumn setTitle:LocalizedString(@"Remove")];
    [lastcolumn setWidth:80];
    [lastcolumn setMinWidth:60];
    [lastcolumn setMaxWidth:100];
    [self.tableview addTableColumn:lastcolumn];
    NSTableColumn * infocolumn = [[NSTableColumn alloc] initWithIdentifier:kInfo];
    [infocolumn setTitle:LocalizedString(@"FoundNum")];
    [infocolumn setWidth:80];
    [infocolumn setMinWidth:60];
    [infocolumn setMaxWidth:100];
    [self.tableview addTableColumn:infocolumn];
    
    [self searchAnswer:nil];
}

-(NSString*)titleWithKey:(NSString*)key identifier:(NSString*)identifier {
    if(key.length==0 || identifier.length == 0)
        return @"";
    if([identifier isEqualToString:KEY]) {
        return key;
    } else  {
        ActionModel *action = [self findActionWith:key identify:identifier];
        if(action){
            return action.value;
        }
        StringModel *model = [self findStringModelWithIdentifier:identifier];
        if(model){
            NSString *value = model.stringDictionary[key];
            return value.length==0 ? @"" : value;
        }
    }
    return @"";
}

-(ActionModel *)findActionWith:(NSString*)key identify:(NSString*)identify {
    for (ActionModel *model in _actionArray) {
        if([model.key isEqualToString:key] && [model.identifier isEqualToString:identify]){
            return model;
        }
    }
    return nil;
}

-(StringModel*)findStringModelWithIdentifier:(NSString*)identifier {
    for (StringModel *model in _stringArray) {
        if([model.identifier isEqualToString:identifier]){
            return model;
        }
    }
    return nil;
}

#pragma mark - Button Action
- (IBAction)openAbout:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/Loongwoo/StringManage"]];
}

- (IBAction)showPreferencesPanel:(id)sender {
    if(self.isRefreshing || self.isChecking)
        return;
    [self.prefsController loadWindow];
    
    NSRect windowFrame = [[self window] frame], prefsFrame = [[self.prefsController window] frame];
    prefsFrame.origin = NSMakePoint(windowFrame.origin.x + (windowFrame.size.width - prefsFrame.size.width) / 2.0,
                                    NSMaxY(windowFrame) - NSHeight(prefsFrame) - 20.0);
    
    [[self.prefsController window] setFrame:prefsFrame display:NO];
    [self.prefsController showWindow:sender];
}

- (IBAction)refresh:(id)sender {
    self.isRefreshing = YES;
    [_actionArray removeAllObjects];
    [self.saveBtn setEnabled:NO];
    
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
                        self.isRefreshing = NO;
                    }];
                });
            } else {
                [_stringArray removeAllObjects];
                [_keyArray removeAllObjects];
                [_keyDict removeAllObjects];
                
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
                self.rawKeyArray = sortedArray;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self refreshTableView];
                    self.isRefreshing = NO;
                });
            }
    });
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
    
    if(_actionArray.count>0){
        [self.saveBtn setEnabled:YES];
    }
}

- (IBAction)checkAction:(id)sender {
    if(self.keyArray.count==0)
        return;
    
    self.isChecking = YES;
    [_infoDict removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        StringSetting *projectSetting = [StringModel projectSettingByProjectName:self.projectName];
        [StringModel findItemsWithProjectPath:projectSetting projectPath:self.projectPath findStrings:self.keyArray block:^(NSString *key, NSArray *items) {
            if(key==nil && items==nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.isChecking=NO;
                });
            }else{
                if(items.count>0){
                    [_infoDict setObject:items forKey:key];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self searchAnswer:nil];
                });
            }
        }];
    });
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
            if(input.stringValue.length==0)
                return;
            if([_keyArray containsObject:input.stringValue]) {
                NSAlert *alert = [[NSAlert alloc]init];
                [alert setMessageText: LocalizedString(@"InputIsExist")];
                [alert addButtonWithTitle: LocalizedString(@"OK")];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert beginSheetModalForWindow:self.window completionHandler:nil];
            } else {
                [_keyArray addObject:input.stringValue];
                [_keyDict setObject:@(KeyTypeAdd) forKey:input.stringValue];
                [self.searchField setStringValue:@""];
                [self searchAnswer:nil];
                [_tableview scrollRowToVisible:_tableview.numberOfRows-1];
            }
        }
    }];
}

- (IBAction)saveAction:(id)sender {
    [self.window makeFirstResponder:nil];
    if(_actionArray.count==0)
        return;
    for (StringModel *model in _stringArray) {
        [model doAction:_actionArray];
    }
    [_actionArray removeAllObjects];
    
    [self refresh:nil];
}

-(void)cellClicked:(id)sender {
    NSInteger column = _tableview.clickedColumn;
    NSInteger row = _tableview.clickedRow;
    if(column<=0 || column > self.tableview.numberOfColumns-2)
        return;
    if(row < 0 || row >= self.tableview.numberOfRows)
        return;
    NSString *key = _showArray[row];
    NSInteger status = [_keyDict[key] integerValue];
    if(status != KeyTypeRemove) {
        [_tableview editColumn:column row:row withEvent:nil select:YES];
    }
}

-(void)doubleAction:(id)sender {
    NSInteger column = _tableview.clickedColumn;
    NSInteger row = _tableview.clickedRow;
    if(column<=0 || column > self.tableview.numberOfColumns-2)
        return;
    if(row < 0 || row >= self.tableview.numberOfRows)
        return;
    NSString *key = _showArray[row];
    StringModel *model = _stringArray[column-1];
    NSInteger status = [_keyDict[key] integerValue];
    if(status != KeyTypeRemove) {
        BOOL found = NO;
        [_actionArray enumerateObjectsUsingBlock:^(ActionModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj.key isEqual:key] && [obj.identifier isEqualToString:model.identifier]){
                [_actionArray removeObject:obj];
            }
        }];
        if(found){
            [self searchAnswer:nil];
        }
    }
}

-(void)removeAction:(id)sender {
    NSButton *button = (NSButton*)sender;
    NSString *key=button.identifier;
    NSInteger status = [_keyDict[key] integerValue];
    if(status == KeyTypeRemove || status == KeyTypeAdd) {
        for (StringModel *model in _stringArray) {
            [_actionArray enumerateObjectsUsingBlock:^(ActionModel * obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.key isEqualToString:key] && [obj.identifier isEqualToString:model.identifier]) {
                    [_actionArray removeObject:obj];
                }
            }];
        }
        [_keyDict removeObjectForKey:key];
        if(status == KeyTypeAdd){
            [_keyArray removeObject:key];
        }
    } else {
        for (StringModel *model in _stringArray) {
            NSString *value = [self titleWithKey:key identifier:model.identifier];
            ActionModel *action = [[ActionModel alloc]init];
            action.actionType = ActionTypeRemove;
            action.identifier = model.identifier;
            action.key = key;
            action.value = value;
            [_actionArray addObject:action];
        }
        [_keyDict setObject:@(KeyTypeRemove) forKey:key];
    }
    
    [self searchAnswer:nil];
}

-(void)infoAction:(id)sender {
    NSButton *button = (NSButton*)sender;
    NSString *key=button.identifier;
    if(self.infoDict && key.length>0){
        NSArray *infos = self.infoDict[key];
        if(infos.count==0)
            return;
        NSPopover* popover = [[NSPopover alloc] init];
        popover.behavior = NSPopoverBehaviorSemitransient;
        StringInfoViewController* viewController = [[StringInfoViewController alloc] initWithArray:infos];
        [popover setContentViewController:viewController];
        [popover showRelativeToRect:CGRectMake(0, 0, 400, 400) ofView:sender preferredEdge:NSMinXEdge];
    }
}

#pragma mark - Notification
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
    
    StringModel *model = [self findStringModelWithIdentifier:identifier];
    if(model==nil)
        return;
    
    __block BOOL found = NO;
    [_actionArray enumerateObjectsUsingBlock:^(ActionModel * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.key isEqualToString:key] && [obj.identifier isEqualToString:model.identifier]) {
            found = YES;
            if(obj.actionType == ActionTypeRemove){
                if(newValue.length>0) {
                    obj.actionType = ActionTypeAdd;
                    obj.value = newValue;
                }
            }else if(obj.actionType == ActionTypeAdd){
                if(newValue.length==0) {
                    obj.actionType = ActionTypeRemove;
                    obj.value = newValue;
                }else{
                    obj.value = newValue;
                }
            }
        }
    }];
    if(!found) {
        if(newValue.length==0) {
            ActionModel *action = [[ActionModel alloc]init];
            action.actionType = ActionTypeRemove;
            action.identifier = model.identifier;
            action.key = key;
            [_actionArray addObject:action];
        }else{
            ActionModel *action = [[ActionModel alloc]init];
            action.actionType = ActionTypeAdd;
            action.identifier = model.identifier;
            action.key = key;
            action.value = newValue;
            [_actionArray addObject:action];
        }
    }
    
    [self searchAnswer:nil];
}

- (void)_onNotifyProjectSettingChanged:(NSNotification*)notification {
    [self refresh:nil];
}

#pragma mark - NSTableViewDelegate & NSTableViewDataSource
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
    NSInteger status = [_keyDict[key] integerValue];
    if([identifier isEqualToString:@"remove"]){
        NSButton *aView = [tableView makeViewWithIdentifier:identifier owner:self];
        if(!aView) {
            aView = [[NSButton alloc]initWithFrame:NSZeroRect];
            [aView setAction:@selector(removeAction:)];
            [aView setTarget:self];
            [aView setState:1];
        }
        if(status == KeyTypeRemove){
            [aView setTitle:LocalizedString(@"撤销")];
        }else{
            [aView setTitle:LocalizedString(@"Remove")];
        }
        [aView setTag:row];
        [aView setIdentifier:key];
        return aView;
    } if([identifier isEqualToString:kInfo]){
        NSArray *items = _infoDict[key];
        NSButton *aView = [tableView makeViewWithIdentifier:identifier owner:self];
        if(!aView) {
            aView = [[NSButton alloc]initWithFrame:NSZeroRect];
            [aView setAction:@selector(infoAction:)];
            [aView setTarget:self];
            [aView setState:1];
        }
        [aView setTag:row];
        [aView setIdentifier:key];
        [aView setTitle:[@(items.count) stringValue]];
        return aView;
    }else {
        NSString *title = [self titleWithKey:key identifier:identifier];
        ActionModel *action = [self findActionWith:key identify:identifier];
        NSTextField *aView = [tableView makeViewWithIdentifier:@"MYCell" owner:self];
        if(!aView) {
            aView = [[NSTextField alloc]initWithFrame:NSZeroRect];
            [aView setTarget:self];
        }
        if(status == KeyTypeRemove){
            [aView setTextColor:[NSColor redColor]];
        }else if (status == KeyTypeAdd) {
            [aView setTextColor: [NSColor grayColor]];
        }else{
            if(action && action.actionType == ActionTypeAdd){
                [aView setTextColor: [NSColor blueColor]];
            }else if (action && action.actionType == ActionTypeRemove){
                [aView setTextColor:[NSColor redColor]];
            }else{
                [aView setTextColor: [NSColor darkGrayColor]];
            }
        }
        [aView setTag:row];
        [aView setIdentifier:identifier];
        [aView setPlaceholderString:title];
        [aView setStringValue:title];
        return aView;
    }
}
@end
