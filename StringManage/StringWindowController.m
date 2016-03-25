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
#import "NSButton+Extension.h"
#import "NSString+Extension.h"
#import "StringEditViewController.h"

#define KEY @"key"
#define REMOVE @"remove"
#define kInfo @"info"

#define kFont [NSFont systemFontOfSize:11]

@interface StringWindowController()

@property (nonatomic, strong)IBOutlet NSTableView *tableview;
@property (weak) IBOutlet NSButton *refreshBtn;
@property (weak) IBOutlet NSButton *saveBtn;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *tipsLabel;
@property (weak) IBOutlet NSTextField *recordLabel;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSButton *addBtn;
@property (weak) IBOutlet NSButton *CheckBtn;
@property (weak) IBOutlet NSProgressIndicator *checkIndicator;
@property (weak) IBOutlet NSButton *showOnlyBtn;
@property (weak) IBOutlet NSButton *untranslatedBtn;
@property (weak) IBOutlet NSButton *unusedBtn;
@property (weak) IBOutlet NSTextField *toastLabel;

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
@property (nonatomic, retain) NSPopover* editPopOver;
@property (nonatomic, retain) NSPopover* infoPopOver;

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
    
    [self.showOnlyBtn setTitle:LocalizedString(@"OnlyShowModified")];
    [self.untranslatedBtn setTitle:LocalizedString(@"Untranslated")];
    [self.unusedBtn setTitle:LocalizedString(@"Unused")];
    [self.searchField setPlaceholderString:LocalizedString(@"Search")];
    [self.saveBtn setTitle:LocalizedString(@"Save")];
    [self.refreshBtn setTitle:LocalizedString(@"Refresh")];
    [self.CheckBtn setTitle:LocalizedString(@"Check")];
    [self.tipsLabel setStringValue:LocalizedString(@"UseTips")];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectSettingChanged:)  name:kNotifyProjectSettingChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:self];
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
        [self.progressIndicator startAnimation:nil];
        [self.refreshBtn setEnabled:NO];
        [self.addBtn setEnabled:NO];
    }else{
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
    for (NSTableColumn *column in columns) {
        [self.tableview removeTableColumn:column];
    }
    
    float columnWidth = (self.tableview.bounds.size.width - 160.0)/(_stringArray.count+1);
    
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
    }
    ActionModel *action = [self findActionWith:key identify:identifier];
    if(action){
        return action.value.length==0 ? @"" : action.value;
    }
    return [self valueInRaw:key identifier:identifier];
}

-(NSString*)valueInRaw:(NSString*)key  identifier:(NSString*)identifier {
    if([identifier isEqualToString:KEY]) {
        return key;
    }
    StringModel *model = [self findStringModelWithIdentifier:identifier];
    if(model){
        NSString *value = model.stringDictionary[key];
        return value.length==0 ? @"" : value;
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

-(StringSetting*)getSetting {
    return [StringModel projectSettingByProjectPath:self.projectPath projectName:self.projectName];
}

-(BOOL)validateKey:(NSString*)key {
    if(key.length==0)
        return NO;
    if([_keyArray containsObject:key]) {
        NSAlert *alert = [[NSAlert alloc]init];
        [alert setMessageText: LocalizedString(@"InputIsExist")];
        [alert addButtonWithTitle: LocalizedString(@"OK")];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
        return NO;
    }
    StringSetting *setting = [self getSetting];
    if (setting.language == 1) {
        NSString *regex = @"[_a-zA-Z][_a-zA-Z0-9]*";
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
        return [predicate evaluateWithObject:key];
    }else{
        return YES;
    }
}

-(void)changeWithKey:(NSString*)key identifier:(NSString*)identifier newValue:(NSString*)newValue {
    NSString *rawValue = [self valueInRaw:key identifier:identifier];
    NSString *oldValue = [self titleWithKey:key identifier:identifier];
    if([oldValue isEqualToString:newValue])
        return;
    ActionModel *action = [self findActionWith:key identify:identifier];
    if(action){
        if([rawValue isEqualToString:newValue]){
            [_actionArray removeObject:action];
        }else{
            action.actionType = (newValue.length==0) ? ActionTypeRemove:ActionTypeAdd;
            action.value = (newValue.length==0) ? rawValue : newValue;
        }
    } else {
        ActionModel *action = [[ActionModel alloc]init];
        action.actionType = (newValue.length==0) ? ActionTypeRemove:ActionTypeAdd;
        action.identifier = identifier;
        action.key = key;
        action.value =  (newValue.length==0) ? rawValue : newValue;
        [_actionArray addObject:action];
    }
    [self searchAnswer:nil];
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
    
    StringSetting *setting = [self getSetting];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *lprojDirectorys = [StringModel lprojDirectoriesWithProjectSetting:setting project:self.projectPath];
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
            
            NSMutableSet *keySet = [NSMutableSet set];
            for (NSString *path in lprojDirectorys) {
                StringModel *model = [[StringModel alloc]initWithPath:path projectSetting:setting];
                [_stringArray addObject:model];
                NSSet *set = [NSSet setWithArray:model.stringDictionary.allKeys];
                [keySet unionSet:set];
            }
            
            NSArray *tmp = [[NSArray alloc]initWithArray:keySet.allObjects];
            NSArray *sortedArray = [tmp sortedArrayUsingSelector:@selector(compare:)];
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
    NSMutableArray *tmp2 = [NSMutableArray array];
    if(self.showOnlyBtn.state){
        for (ActionModel *model in _actionArray) {
            if (![tmp2 containsObject:model.key]) {
                [tmp2 addObject:model.key];
            }
        }
    }else{
        [tmp2 addObjectsFromArray:_keyArray];
    }
    
    for (NSString *string in [tmp2 copy]) {
        if(self.unusedBtn.state){
            NSArray *arr = _infoDict[string];
            if (arr.count > 0) {
                [tmp2 removeObject:string];
            }
        }
        
        BOOL exist = YES;
        BOOL found = searchString.length==0 || [string contain:searchString];
        for (StringModel *model in _stringArray) {
            NSString *str2 = model.stringDictionary[string];
            ActionModel *action = [self findActionWith:string identify:model.identifier];
            exist = exist && (str2.length || (action && action.value.length));
            found = found || ([str2 contain:searchString] || (action && [action.value contain:searchString]));
        }
        if (!found || (found && (self.untranslatedBtn.state && exist))) {
            [tmp2 removeObject:string];
        }
    }
    
    self.showArray = [tmp2 sortedArrayUsingSelector:@selector(compare:)];
    self.recordLabel.stringValue = [NSString stringWithFormat:LocalizedString(@"RecordNumMsg"),self.showArray.count];
    [self.saveBtn setEnabled:(_actionArray.count>0 && !self.isChecking)];
    [self.tableview reloadData];
}

- (IBAction)checkAction:(id)sender {
    if(self.keyArray.count==0)
        return;
    
    self.isChecking = YES;
    [_infoDict removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [StringModel findItemsWithProjectPath:[self getSetting]
                                  projectPath:self.projectPath
                                  findStrings:self.keyArray
                                        block:^(NSString *key, NSArray *items, float progress) {
            if(items.count>0){
                [_infoDict setObject:items forKey:key];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self searchAnswer:nil];
                self.checkIndicator.doubleValue = progress;
            });
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isChecking=NO;
        });
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
            NSString *text = [input.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if(![self validateKey:text])
                return;
            [_keyArray addObject:text];
            [_keyDict setObject:@(KeyTypeAdd) forKey:text];
            
            for (StringModel *model in _stringArray) {
                ActionModel *action = [[ActionModel alloc]init];
                action.actionType = ActionTypeAdd;
                action.identifier = model.identifier;
                action.key = text;
                action.value = @"";
                [_actionArray addObject:action];
            }
            
            [self.searchField setStringValue:@""];
            [self searchAnswer:nil];
            
            [_tableview scrollRowToVisible:[_showArray indexOfObject:text]];
        }
    }];
}

- (IBAction)saveAction:(id)sender {
    if(_actionArray.count==0)
        return;
    StringSetting *setting = [self getSetting];
    for (StringModel *model in _stringArray) {
        NSPredicate *predicte = [NSPredicate predicateWithFormat:@"identifier == %@",model.identifier];
        NSArray *arr = [self.actionArray filteredArrayUsingPredicate:predicte];
        [model doAction:arr projectSetting:setting];
    }
    [_actionArray removeAllObjects];
    
    [self refresh:nil];
}

-(void)cellClicked:(id)sender {
    if (self.isChecking) {
        return;
    }
    NSInteger column = _tableview.clickedColumn;
    NSInteger row = _tableview.clickedRow;
    if(column<=0 || column >= self.tableview.numberOfColumns-2)
        return;
    if(row < 0 || row >= self.tableview.numberOfRows)
        return;
    NSString *key = _showArray[row];
    NSInteger status = [_keyDict[key] integerValue];
    if(status != KeyTypeRemove) {
        StringModel *model = _stringArray[column-1];
        if(model){
            NSString *identifier = model.identifier;
            if (self.infoPopOver && self.infoPopOver.isShown) {
                [self.infoPopOver close],self.infoPopOver = nil;
            }
            if (self.editPopOver && self.editPopOver.isShown) {
                StringEditViewController *editVC = (StringEditViewController*)[self.editPopOver contentViewController];
                [self.editPopOver close],self.editPopOver = nil;
                if ([key isEqualToString:editVC.key] && [identifier isEqualToString:editVC.identifier]) {
                    return;
                }
            }
            NSDictionary *dict = @{@"Key":key, @"Identifier":identifier};
            [self performSelector:@selector(startEditWithDict:) withObject:dict afterDelay:0.3];
        }
    }
    
}

-(void)startEditWithDict:(NSDictionary*)dict{
    NSString *key = dict[@"Key"];
    NSString *identifier = dict[@"Identifier"];
    NSInteger column = [_tableview columnWithIdentifier:identifier];
    NSInteger row = [_showArray indexOfObject:key];
    NSString *title = nil;
    ActionModel *action = [self findActionWith:key identify:identifier];
    if(action){
        title = action.actionType==ActionTypeRemove ? @"" : action.value;
    }
    if(title==nil){
        title = [self valueInRaw:key identifier:identifier];
    }
    CGRect rect = [_tableview frameOfCellAtColumn:column row:row];
    StringEditViewController* viewController = [[StringEditViewController alloc] initWithKey:key
                                                                                  identifier:identifier
                                                                                value:title];
    self.editPopOver = [[NSPopover alloc] init];
    self.editPopOver.delegate = self;
    self.editPopOver.behavior = NSPopoverBehaviorSemitransient;
    [self.editPopOver setContentViewController:viewController];
    [self.editPopOver showRelativeToRect:rect ofView:_tableview preferredEdge:NSRectEdgeMinY];
}

-(void)doubleAction:(id)sender {
    if (self.isChecking) {
        return;
    }
    NSInteger column = _tableview.clickedColumn;
    NSInteger row = _tableview.clickedRow;
    if(column<0 || column >= self.tableview.numberOfColumns-2)
        return;
    if(row < 0 || row >= self.tableview.numberOfRows)
        return;
    [[NSObject class] cancelPreviousPerformRequestsWithTarget:self];
    NSString *key = _showArray[row];
    NSString *identifier = nil;
    if(column==0){
        identifier=@"key";
    }else{
        StringModel *model = _stringArray[column-1];
        identifier = model.identifier;
    }
    NSInteger status = [_keyDict[key] integerValue];
    if(status != KeyTypeRemove) {
        ActionModel *action = [self findActionWith:key identify:identifier];
        if(action){
            [_actionArray removeObject:action];
            [self searchAnswer:nil];
        }
        
        NSString *value = [self valueInRaw:key identifier:identifier];
        
        if (column == 0) {
            StringSetting *setting = [self getSetting];
            if (setting.language == StringLanguageSwift) {
                value = [NSString stringWithFormat:@"\"%@\"",value];
            }else{
                value = [NSString stringWithFormat:@"@\"%@\"",value];
            }
            NSString *wrapper = [NSString stringWithString:setting.doubleClickWrapper];
            NSRange start = [wrapper rangeOfString:@"("];
            NSRange end = [wrapper rangeOfString:@")"];
            if (start.location != NSNotFound && end.location > start.location) {
                NSRange keyRange = [wrapper rangeOfString:@"KEY"
                                                  options:NSCaseInsensitiveSearch
                                                    range:NSMakeRange(start.location, end.location-start.location)];
                if (keyRange.location != NSNotFound) {
                    value = [wrapper stringByReplacingCharactersInRange:keyRange withString:value];
                }
            }
        }
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
        [pasteboard setString:value forType:NSStringPboardType];
        
        [self makeToast:value];
    }
}

-(void)makeToast:(NSString *)string{
    [[NSObject class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideToast) object:nil];
    
    NSString *tmp = [NSString stringWithFormat:LocalizedString(@"CopyToPasteboard"),string];
    CGFloat width = self.window.contentView.frame.size.width-100;
    NSFont *font =[NSFont systemFontOfSize:24.0];
    CGRect rect = [tmp sizeWithWidth:width font:font];
    rect.size.width += 15.0f;
    rect.size.height += 5.0f;
    rect.origin = CGPointMake(CGRectGetMidX(self.window.contentView.bounds) - CGRectGetMidX(rect), 70.0f);
    self.toastLabel.frame = rect;
    self.toastLabel.stringValue = tmp;
    self.toastLabel.hidden = NO;
    [self performSelector:@selector(hideToast) withObject:nil afterDelay:2];
}

-(void)hideToast{
    self.toastLabel.hidden = YES;
}

-(void)removeAction:(id)sender {
    if (self.isChecking) {
        return;
    }
    NSButton *button = (NSButton*)sender;
    NSString *key=button.identifier;
    NSInteger status = [_keyDict[key] integerValue];
    for (ActionModel *action in [_actionArray copy]) {
        if ([action.key isEqualToString:key]) {
            [_actionArray removeObject:action];
        }
    }
    if(status == KeyTypeRemove || status == KeyTypeAdd) {
        [_keyDict removeObjectForKey:key];
        if(status == KeyTypeAdd){
            [_keyArray removeObject:key];
        }
    } else {
        for (StringModel *model in _stringArray) {
            ActionModel *action = [[ActionModel alloc]init];
            action.actionType = ActionTypeRemove;
            action.identifier = model.identifier;
            action.key = key;
            action.value = [self valueInRaw:key identifier:model.identifier];
            [_actionArray addObject:action];
        }
        [_keyDict setObject:@(KeyTypeRemove) forKey:key];
    }
    [self searchAnswer:nil];
}

-(void)infoAction:(id)sender {
    if (self.isChecking) {
        return;
    }
    NSButton *button = (NSButton*)sender;
    NSString *key=button.identifier;
    if(self.infoDict && key.length>0){
        if (self.editPopOver && self.editPopOver.isShown) {
            [self.editPopOver close],self.editPopOver = nil;
        }
        if (self.infoPopOver && self.infoPopOver.isShown) {
            StringInfoViewController *infoVC = (StringInfoViewController*)[self.infoPopOver contentViewController];
            [self.infoPopOver close], self.infoPopOver = nil;
            if ([key isEqualToString:infoVC.key]) {
                return;
            }
        }
        NSArray *infos = self.infoDict[key];
        if(infos.count==0)
            return;
        StringInfoViewController* viewController = [[StringInfoViewController alloc] initWithArray:infos];
        viewController.key = key;
        
        self.infoPopOver = [[NSPopover alloc] init];
        self.infoPopOver.behavior = NSPopoverBehaviorSemitransient;
        [self.infoPopOver setContentViewController:viewController];
        [self.infoPopOver showRelativeToRect:CGRectMake(0, 0, 400, 400) ofView:sender preferredEdge:NSMinXEdge];
    }
}

#pragma mark - Notification
- (void)projectSettingChanged:(NSNotification*)notification {
    [_infoDict removeAllObjects];
    [self refresh:nil];
}

- (void)windowDidResize:(NSNotification *)notification {
    [_tableview reloadData];
}

#pragma mark - NSPopoverDelegate
- (void)popoverDidClose:(NSNotification*)notification {
    NSPopover* popOver = [notification object];
    if ([popOver isKindOfClass:[NSPopover class]] == NO) {
        return;
    }
    id controller = [popOver contentViewController];
    if ([controller isKindOfClass:[StringEditViewController class]] == NO) {
        return;
    }
    StringEditViewController* editViewController = (StringEditViewController*)controller;
    NSString *string1 = editViewController.textView.string;
    NSString *string2 = [string1 stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    [self changeWithKey:editViewController.key identifier:editViewController.identifier newValue:string2];
}

#pragma mark - NSTableViewDelegate & NSTableViewDataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.showArray.count;
}

- (void)tableViewColumnDidResize:(NSNotification *)notification{
    [_tableview reloadData];
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    float height = 17;
    NSString *key = _showArray[row];
    for (ActionModel *model in _actionArray) {
        if ([model.key isEqualToString:key]) {
            NSTableColumn *column = [_tableview tableColumnWithIdentifier:model.identifier];
            float tmpHeight = ceilf([model.value sizeWithWidth:column.width font:kFont].size.height);
            height = MAX(height, tmpHeight);
        }
    }
    for (StringModel *model in _stringArray) {
        NSString *tmp = model.stringDictionary[key];
        NSTableColumn *column = [_tableview tableColumnWithIdentifier:model.identifier];
        float tmpHeight = ceilf([tmp sizeWithWidth:column.width font:kFont].size.height);
        height = MAX(height, tmpHeight);
    }
    return height;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if(row>=self.showArray.count)
        return nil;
    NSString *identifier=[tableColumn identifier];
    NSString *key = self.showArray[row];
    if([identifier isEqualToString:REMOVE]){
        NSButton *aView = [tableView makeViewWithIdentifier:identifier owner:self];
        if(!aView) {
            aView = [[NSButton alloc]initWithFrame:NSZeroRect];
            [aView setButtonType:NSToggleButton];
            [aView setTitle:LocalizedString(@"Remove") textColor:[NSColor blackColor]];
            [aView setAlternateTitle:LocalizedString(@"Revoke") textColor:[NSColor redColor]];
            [aView setAction:@selector(removeAction:)];
            [aView setTarget:self];
        }
        NSInteger status = [_keyDict[key] integerValue];
        [aView setHighlighted:status];
        [aView setTag:row];
        [aView setIdentifier:key];
        return aView;
    }else if([identifier isEqualToString:kInfo]){
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
        NSTextField *aView = [tableView makeViewWithIdentifier:@"MYCell" owner:self];
        if(!aView) {
            aView = [[NSTextField alloc]initWithFrame:NSZeroRect];
            [aView setTextColor:[NSColor blackColor]];
            [aView setBordered:NO];
            [aView setFont:kFont];
            [aView setEditable:NO];
            [aView setLineBreakMode:NSLineBreakByWordWrapping];
        }
        if([identifier isEqualToString:KEY]){
            NSInteger status = [_keyDict[key] integerValue];
            if(status == KeyTypeRemove){
                [aView setBackgroundColor:[NSColor redColor]];
            }else if (status == KeyTypeAdd) {
                [aView setBackgroundColor: [NSColor colorWithRed:0 green:0.8 blue:0 alpha:1.0]];
            }else{
                [aView setBackgroundColor: [NSColor clearColor]];
            }
            [aView setStringValue:_showArray[row]];
        }else{
            ActionModel *action = [self findActionWith:key identify:identifier];
            NSString *rawValue = [self valueInRaw:key identifier:identifier];
            if (action) {
                if(action.actionType == ActionTypeRemove){
                    [aView setBackgroundColor:[NSColor redColor]];
                }else{
                    if (rawValue.length==0) {
                        [aView setBackgroundColor: [NSColor colorWithRed:0 green:0.8 blue:0 alpha:1.0]];
                    }else{
                        [aView setBackgroundColor: [NSColor blueColor]];
                    }
                }
                [aView setStringValue:action.value];
            }else{
                [aView setBackgroundColor: [NSColor clearColor]];
                [aView setStringValue:rawValue];
            }
        }
        [aView setTag:row];
        [aView setIdentifier:identifier];
        return aView;
    }
}
@end
