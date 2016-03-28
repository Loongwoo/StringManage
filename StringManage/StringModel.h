//
//  StringModel.h
//  StringManage
//
//  Created by kiwik on 1/13/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "StringSetting.h"
#import "NSString+Extension.h"
#import "NSArray+Extension.h"

@interface DVTChoice : NSObject
- (id)initWithTitle:(id)arg1 toolTip:(id)arg2 image:(id)arg3 representedObject:(id)arg4;
@end

@interface DVTTextDocumentLocation : NSObject
@property (readonly) NSRange characterRange;
@property (readonly) NSRange lineRange;
@end

@interface DVTTextPreferences : NSObject
+ (id)preferences;
@property BOOL trimWhitespaceOnlyLines;
@property BOOL trimTrailingWhitespace;
@property BOOL useSyntaxAwareIndenting;
@end

@interface DVTSourceTextStorage : NSTextStorage
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString*)string withUndoManager:(id)undoManager;
- (NSRange)lineRangeForCharacterRange:(NSRange)range;
- (NSRange)characterRangeForLineRange:(NSRange)range;
- (void)indentCharacterRange:(NSRange)range undoManager:(id)undoManager;
@end

@interface DVTFileDataType : NSObject
@property (readonly) NSString* identifier;
@end

@interface DVTFilePath : NSObject
@property (readonly) NSURL* fileURL;
@property (readonly) DVTFileDataType* fileDataTypePresumed;
@end

@interface IDEContainerItem : NSObject
@property (readonly) DVTFilePath* resolvedFilePath;
@end

@interface IDEGroup : IDEContainerItem

@end

@interface IDEFileReference : IDEContainerItem

@end

@interface IDENavigableItem : NSObject
@property (readonly) IDENavigableItem* parentItem;
@property (readonly) id representedObject;

@end

@interface IDEFileNavigableItem : IDENavigableItem
@property (readonly) DVTFileDataType* documentType;
@property (readonly) NSURL* fileURL;
@end

@interface IDEStructureNavigator : NSObject
@property (retain) NSArray* selectedObjects;
@end

@interface IDENavigableItemCoordinator : NSObject
- (id)structureNavigableItemForDocumentURL:(id)arg1 inWorkspace:(id)arg2 error:(id*)arg3;
@end

@interface IDENavigatorArea : NSObject
@property NSArrayController* extensionsController;
- (id)currentNavigator;
@end

@interface IDEWorkspaceTabController : NSObject
@property (readonly) IDENavigatorArea* navigatorArea;
@property (readonly) IDEWorkspaceTabController* structureEditWorkspaceTabController;
@end

@interface IDEDocumentController : NSDocumentController
+ (IDEDocumentController*)sharedDocumentController;
+ (id)editorDocumentForNavigableItem:(id)arg1;
+ (id)retainedEditorDocumentForNavigableItem:(id)arg1 error:(id*)arg2;
+ (void)releaseEditorDocument:(id)arg1;

@end

@interface IDESourceCodeDocument : NSDocument
- (DVTSourceTextStorage*)textStorage;
- (NSUndoManager*)undoManager;
@end

@interface IDESourceCodeComparisonEditor : NSObject
@property (readonly) NSTextView* keyTextView;
@property (retain) NSDocument* primaryDocument;
@end

@interface IDESourceCodeEditor : NSObject
@property (retain) NSTextView* textView;
- (IDESourceCodeDocument*)sourceCodeDocument;
@end

@interface IDEEditorContext : NSObject
- (id)editor; // returns the current editor. If the editor is the code editor, the class is `IDESourceCodeEditor`
@end

@interface IDEEditorArea : NSObject
- (IDEEditorContext*)lastActiveEditorContext;
@end

@interface IDEConsoleArea : NSObject
- (IDEEditorContext*)lastActiveEditorContext;
@end

@interface IDEWorkspaceWindowController : NSObject
@property (readonly) IDEWorkspaceTabController* activeWorkspaceTabController;
- (IDEEditorArea*)editorArea;
@end

@interface IDEWorkspace : NSWorkspace
@property (readonly) DVTFilePath* representingFilePath;
@end

@interface IDEWorkspaceDocument : NSDocument
@property (readonly) IDEWorkspace* workspace;
@end

@interface StringItem : NSObject
@property (nonatomic, copy) NSString* filePath;
@property (nonatomic, assign) NSUInteger lineNumber;
@property (nonatomic, copy) NSString* content;
@end

typedef void (^onFoundBlock)(NSString* key, NSArray *items, float progress);

@class ActionModel;
@interface StringModel : NSObject

@property (nonatomic, strong) NSString *path;//lproj directory
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *identifier;//country code
@property (nonatomic, strong) NSMutableDictionary *stringDictionary;//dictionary for all strings

-(void)doAction:(NSArray*)actions projectSetting:(StringSetting*)projectSetting;
- (instancetype)initWithPath:(NSString*)path projectSetting:(StringSetting*)projectSetting;

+ (IDEWorkspaceDocument*)currentWorkspaceDocument;
+(NSInteger)devLanguageWithProjectPath:(NSString*)projectPath;
+ (NSString*)rootPathMacro;
+ (NSString*)addPathSlash:(NSString*)path;
+ (NSString*)explandRootPathMacro:(NSString*)path projectPath:(NSString*)projectPath;
+ (NSArray*)explandRootPathMacros:(NSArray*)paths projectPath:(NSString*)projectPath;
+(NSArray*)lprojDirectoriesWithProjectSetting:(StringSetting*)setting project:(NSString*)project;
+ (void)findItemsWithProjectPath:(StringSetting*)projectSetting projectPath:(NSString*)projectPath findStrings:(NSArray*)findStrings block:(onFoundBlock)block;
+ (BOOL)openItem:(StringItem*)item;
+ (StringSetting*)projectSettingByProjectPath:(NSString*)projectPath projectName:(NSString*)projectName;
+ (void)saveProjectSetting:(StringSetting*)projectSetting ByProjectName:(NSString*)projectName;
@end

typedef enum : NSUInteger {
    ActionTypeAdd,
    ActionTypeRemove,
} ActionType;

@interface ActionModel : NSObject

@property (nonatomic, assign)ActionType actionType;
@property (nonatomic, strong)NSString *identifier;
@property (nonatomic, strong)NSString *key;
@property (nonatomic, strong)NSString *value;

@end

extern NSString* const kNotifyProjectSettingChanged;