//
//  StringModel.m
//  StringManage
//
//  Created by kiwik on 1/13/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "StringModel.h"
#import "StringSetting.h"
#import "NSData+Split.h"
#import "StringSetting.h"
#import <objc/runtime.h>

static NSString * const kRegularExpressionPattern = @"(\"(\\S+.*\\S+)\"|(\\S+.*\\S+))\\s*=\\s*\"(.*)\";$";

@implementation StringModel

#pragma mark - Private
- (instancetype)initWithPath:(NSString*)path projectSetting:(StringSetting*)projectSetting{
    self = [super init];
    if (self) {
        self.path = path;
        self.filePath = [path stringByAppendingPathComponent:projectSetting.searchTableName];
        self.identifier = [[path lastPathComponent] stringByDeletingPathExtension];
        
        self.stringDictionary = [NSMutableDictionary dictionary];
        NSString *string = [NSString stringWithContentsOfFile:self.filePath usedEncoding:nil error:nil];
        
        NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:kRegularExpressionPattern options:0 error:nil];
        
        __block NSInteger lineOffset = 0;
        [string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            NSRange keyRange;
            NSRange valueRange;
            NSString *key = nil;
            NSString *value = nil;
            
            // Find definition
            NSTextCheckingResult *result = [regularExpression firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            
            if (result.range.location != NSNotFound && result.numberOfRanges == 5) {
                keyRange = [result rangeAtIndex:2];
                if (keyRange.location == NSNotFound) keyRange = [result rangeAtIndex:3];
                
                valueRange = [result rangeAtIndex:4];
                
                key = [line substringWithRange:keyRange];
                value = [line substringWithRange:valueRange];
            }
            
            if (key && value) {
                [_stringDictionary setObject:value forKey:key];
            }
            
            // Move offset
            NSRange lineRange = [string lineRangeForRange:NSMakeRange(lineOffset, 0)];
            lineOffset += lineRange.length;
        }];
    }
    return self;
}

-(void)doAction:(NSArray*)actions {
    NSString *string = [NSString stringWithContentsOfFile:self.filePath usedEncoding:nil error:nil];
    
    NSMutableString *mutableString = [[NSMutableString alloc]initWithString:string];
    
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:kRegularExpressionPattern options:0 error:nil];
    
    for (ActionModel *action in actions) {
        if(![action.identifier isEqualToString:_identifier]) {
            continue;
        }
        __block NSInteger lineOffset = 0;
        __block BOOL found = NO;
        [mutableString enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            NSRange keyRange;
            NSRange valueRange;
            NSString *key = nil;
            NSString *value = nil;
            
            NSRange lineRange = [mutableString lineRangeForRange:NSMakeRange(lineOffset, 0)];
            NSTextCheckingResult *result = [regularExpression firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (result.range.location != NSNotFound && result.numberOfRanges == 5) {
                keyRange = [result rangeAtIndex:2];
                
                if (keyRange.location == NSNotFound) {
                    keyRange = [result rangeAtIndex:3];
                }
                valueRange = [result rangeAtIndex:4];
                key = [line substringWithRange:keyRange];
                value = [line substringWithRange:valueRange];
            }
            
            if (key && value) {
                if([key isEqualToString:action.key]) {
                    found = YES;
                    if(action.actionType == ActionTypeRemove) {
                        [mutableString deleteCharactersInRange:lineRange];
                    } else {
                        valueRange.location += lineOffset;
                        [mutableString deleteCharactersInRange:valueRange];
                        [mutableString insertString:action.value atIndex:valueRange.location];
                    }
                    *stop = YES;
                }
            }
            
            lineOffset += lineRange.length;
        }];
        if(!found && action.actionType == ActionTypeAdd) {
            if(![mutableString hasSuffix:@"\n"])
                [mutableString appendFormat:@"\n"];
            [mutableString appendFormat:@"\"%@\"=\"%@\";",action.key, action.value];
        }
    }
    //write to filepath
    NSError *error = nil;
    BOOL result = [mutableString writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if(!result) {
        NSLog(@"failed to save %@",[error description]);
    }
}

#pragma mark - override
-(NSString*)description {
    return [NSString stringWithFormat:@"path %@\n filePath %@\n identifier %@\n stringDictionary %@",_path,_filePath,_identifier,_stringDictionary];
}

#pragma mark - Public
+ (IDEWorkspaceTabController*)tabController {
    NSWindowController* currentWindowController = [[NSApp keyWindow] windowController];
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController* workspaceController = (IDEWorkspaceWindowController*)currentWindowController;
        return workspaceController.activeWorkspaceTabController;
    }
    return nil;
}

+ (id)currentEditor {
    NSWindowController* currentWindowController = [[NSApp mainWindow] windowController];
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController* workspaceController = (IDEWorkspaceWindowController*)currentWindowController;
        IDEEditorArea* editorArea = [workspaceController editorArea];
        IDEEditorContext* editorContext = [editorArea lastActiveEditorContext];
        return [editorContext editor];
    }
    return nil;
}

+ (IDEWorkspaceDocument*)currentWorkspaceDocument {
    NSWindowController* currentWindowController = [[NSApp mainWindow] windowController];
    id document = [currentWindowController document];
    if (currentWindowController && [document isKindOfClass:NSClassFromString(@"IDEWorkspaceDocument")]) {
        return (IDEWorkspaceDocument*)document;
    }
    return nil;
}

+ (IDESourceCodeDocument*)currentSourceCodeDocument {
    IDESourceCodeEditor* editor = [self currentEditor];
    if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return editor.sourceCodeDocument;
    }
    if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        if ([[(IDESourceCodeComparisonEditor*)editor primaryDocument] isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
            return (id)[(IDESourceCodeComparisonEditor*)editor primaryDocument];
        }
    }
    return nil;
}

+(BOOL)isSwiftWithProjectPath:(NSString*)projectPath {
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:projectPath];
    NSString *filePath = nil;
    while (filePath = [enumerator nextObject]){
        NSString *file = [filePath lastPathComponent];
        if([file isEqualToString:@"AppDelegate.swift"]) {
            return YES;
        }
    }
    return NO;
}

+ (NSArray*)explandRootPathMacros:(NSArray*)paths projectPath:(NSString*)projectPath {
    if (projectPath == nil) {
        return paths;
    }
    
    NSMutableArray* explandPaths = [NSMutableArray arrayWithCapacity:[paths count]];
    for (NSString* path in paths) {
        [explandPaths addObject:[StringModel explandRootPathMacro:path projectPath:projectPath]];
    }
    return explandPaths;
}

+ (NSString*)explandRootPathMacro:(NSString*)path projectPath:(NSString*)projectPath {
    projectPath = [StringModel addPathSlash:projectPath];
    path = [path stringByReplacingOccurrencesOfString:[StringModel rootPathMacro] withString:projectPath];
    return [StringModel addPathSlash:path];
}

+ (NSString*)addPathSlash:(NSString*)path {
    if ([path length] > 0) {
        if ([path characterAtIndex:([path length] - 1)] != '/') {
            path = [NSString stringWithFormat:@"%@/", path];
        }
    }
    return path;
}

+ (NSString*)rootPathMacro {
    return [StringModel addPathSlash:@"$(SRCROOT)"];
}

+ (NSString*)_settingDirectory {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* settingDirectory = [(NSString*)[paths objectAtIndex:0] stringByAppendingPathComponent:@"StringManage"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:settingDirectory] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:settingDirectory  withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return settingDirectory;
}

+ (NSString*)_tempFileDirectory {
    NSString* tempFileDirectory = [[self _settingDirectory] stringByAppendingPathComponent:@"Temp"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempFileDirectory] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:tempFileDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return tempFileDirectory;
}

+ (void)cleanAllTempFiles {
    [StringModel  scanFolder:[StringModel _tempFileDirectory] findedItemBlock:^(NSString* fullPath, BOOL isDirectory, BOOL* skipThis, BOOL* stopAll) {
         [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
     }];
}

typedef void (^OnFindedItem)(NSString* fullPath, BOOL isDirectory, BOOL* skipThis, BOOL* stopAll);

+ (void)scanFolder:(NSString*)folder findedItemBlock:(OnFindedItem)findedItemBlock {
    BOOL stopAll = NO;
    
    NSFileManager* localFileManager = [[NSFileManager alloc] init];
    NSDirectoryEnumerationOptions option = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants;
    NSDirectoryEnumerator* directoryEnumerator = [localFileManager enumeratorAtURL:[NSURL fileURLWithPath:folder] includingPropertiesForKeys:nil options:option errorHandler:nil];
    for (NSURL* theURL in directoryEnumerator) {
        if (stopAll) {
            break;
        }
        
        NSString* fileName = nil;
        [theURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
        
        NSNumber* isDirectory = nil;
        [theURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        
        BOOL skinThis = NO;
        
        BOOL directory = [isDirectory boolValue];
        
        findedItemBlock([theURL path], directory, &skinThis, &stopAll);
        
        if (skinThis) {
            [directoryEnumerator skipDescendents];
        }
    }
}

+ (NSArray*)findFileNameWithProjectPath:(NSString*)projectPath
                            includeDirs:(NSArray*)includeDirs
                            excludeDirs:(NSArray*)excludeDirs
                              fileTypes:(NSSet*)fileTypes {
    includeDirs = [StringModel explandRootPathMacros:includeDirs projectPath:projectPath];
    excludeDirs = [StringModel explandRootPathMacros:excludeDirs projectPath:projectPath];
    fileTypes = [StringModel lowercaseFileTypes:fileTypes];
    NSMutableArray* allFilePaths = [NSMutableArray arrayWithCapacity:1000];
    for (NSString* includeDir in includeDirs) {
        [StringModel scanFolder:includeDir findedItemBlock:^(NSString* fullPath, BOOL isDirectory, BOOL* skipThis, BOOL* stopAll) {
             if (isDirectory) {
                 for (NSString *excludeDir in excludeDirs) {
                     if ([fullPath hasPrefix:excludeDir]) {
                         *skipThis = YES;
                         return;
                     }
                 }
             } else {
                 if ([fileTypes containsObject:
                      [[fullPath pathExtension] lowercaseString]]) {
                     [allFilePaths addObject:fullPath];
                 }
             }
         }];
    }
    return allFilePaths;
}

+ (NSSet*)lowercaseFileTypes:(NSSet*)fileTypes {
    NSMutableSet* set = [NSMutableSet setWithCapacity:[fileTypes count]];
    for (NSString* fileType in fileTypes) {
        [set addObject:[fileType lowercaseString]];
    }
    return set;
}

+ (void)findItemsWithProjectPath:(StringSetting*)projectSetting projectPath:(NSString*)projectPath findStrings:(NSArray*)findStrings block:(onFoundBlock)block{
    if(findStrings.count==0)
        return;
    NSArray* includeDirs = [projectSetting includeDirs];
    if ([includeDirs count] == 0) {
        return;
    }
    
    NSString* tempFilePath = [[StringModel _tempFileDirectory] stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    NSSet *set = [NSSet setWithArray:projectSetting.searchTypes];
    @try {
        [StringModel findItemsWithProjectPath:projectPath
                                  includeDirs:[projectSetting includeDirs]
                                  excludeDirs:[projectSetting excludeDirs]
                                    fileTypes:set
                                 tempFilePath:tempFilePath
                                  findStrings:findStrings
                                        block:block];
    }
    @catch (NSException* exception) {
    }
    @finally {
        [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil]; // HAVE TO delete temp file.
    }
}

+ (void)findItemsWithProjectPath:(NSString*)projectPath
                         includeDirs:(NSArray*)includeDirs
                         excludeDirs:(NSArray*)excludeDirs
                           fileTypes:(NSSet*)fileTypes
                        tempFilePath:(NSString*)tempFilePath
             findStrings:(NSArray*)findStrings
                                    block:(onFoundBlock)block{
    NSArray* filePaths = [StringModel findFileNameWithProjectPath:projectPath
                                                     includeDirs:includeDirs
                                                     excludeDirs:excludeDirs
                                                       fileTypes:fileTypes];
    // xargs -0 need "\0" as separtor
    NSData* dataAllFilePaths = [[filePaths componentsJoinedByString:@"\0"] dataUsingEncoding:NSUTF8StringEncoding];

    if ([dataAllFilePaths writeToFile:tempFilePath atomically:NO] == NO) {
        return;
    }
    
    NSString* shellPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"find" ofType:@"sh"];
    if(shellPath.length==0){
        return;
    }
    
    for (NSString *findString in findStrings) {
        if (findString.length==0)
            continue;
        NSFileHandle* inputFileHandle = [NSFileHandle fileHandleForReadingAtPath:tempFilePath];
        if (inputFileHandle == nil) {
            return;
        }
        
        NSTask* task = [[NSTask alloc] init];
        [task setLaunchPath:@"/bin/bash"];
        [task setArguments:@[shellPath, findString]];
        [task setStandardInput:inputFileHandle];
        [task setStandardOutput:[NSPipe pipe]];
        NSFileHandle* readHandle = [[task standardOutput] fileHandleForReading];
        [task launch];
        
        NSData* data = [readHandle readDataToEndOfFile];
        [inputFileHandle closeFile];
        
        NSArray* dataArray = [data componentsSeparatedByByte:'\n'];
        NSMutableArray* results = [NSMutableArray arrayWithCapacity:[dataArray count]];
        for (NSData* dataItem in dataArray) {
            NSString* string = [[NSString alloc] initWithData:dataItem encoding:NSUTF8StringEncoding];
            if (string != nil && string.length>0) {
                StringItem *item = [StringModel itemFromLine:string];
                [results addObject:item];
            }
        }
        if(block){
            block(findString, results);
        }
    }
    if(block){
        block(nil, nil);
    }
}

+ (StringItem*)itemFromLine:(NSString*)line{
    NSMutableArray* lineComponents = [[line componentsSeparatedByString:@":"] mutableCopy];
    if (lineComponents.count < 3) {
        return nil;
    }
    NSArray *subArray = [lineComponents subarrayWithRange:NSMakeRange(2, lineComponents.count-2)];
    NSString *content = [[NSString alloc]initWithString:[subArray componentsJoinedByString:@":"]];
    StringItem* item = [[StringItem alloc] init];
    item.filePath = lineComponents[0];
    item.lineNumber = [lineComponents[1] integerValue];
    item.content = content;
    return item;
}

+ (void)highlightItem:(StringItem*)item inTextView:(NSTextView*)textView{
    NSUInteger lineNumber = item.lineNumber - 1;
    NSString* text = [textView string];
    NSRegularExpression* re =[NSRegularExpression regularExpressionWithPattern:@"\n" options:0 error:nil];
    NSArray* result = [re matchesInString:text options:NSMatchingReportCompletion range:NSMakeRange(0, text.length)];
    if (result.count <= lineNumber) {
        return;
    }
    NSUInteger location = 0;
    NSTextCheckingResult* aim = result[lineNumber];
    location = aim.range.location;
    NSRange range = [text lineRangeForRange:NSMakeRange(location, 0)];
    [textView scrollRangeToVisible:range];
    [textView setSelectedRange:range];
}

+ (BOOL)openItem:(StringItem*)item{
    NSWindowController* currentWindowController = [[NSApp mainWindow] windowController];
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        id<NSApplicationDelegate> appDelegate = (id<NSApplicationDelegate>)[NSApp delegate];
        if ([appDelegate application:NSApp openFile:item.filePath]) {
            IDESourceCodeEditor* editor = [StringModel currentEditor];
            if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
                NSTextView* textView = editor.textView;
                if (textView) {
                    [self highlightItem:item inTextView:textView];
                    return YES;
                }
            }
        }
    }
    
    BOOL result = [[NSWorkspace sharedWorkspace] openFile:item.filePath withApplication:@"Xcode"];
    if (result) {
        NSString* theSource = [NSString  stringWithFormat: @"do shell script \"xed --line %ld \" & quoted form of \"%@\"", item.lineNumber, item.filePath];
        NSAppleScript* theScript = [[NSAppleScript alloc] initWithSource:theSource];
        [theScript performSelectorInBackground:@selector(executeAndReturnError:) withObject:nil];
        return NO;
    }
    return result;
}


+(NSArray*)lprojDirectoriesWithProjectSetting:(StringSetting*)setting project:(NSString*)project{
    NSMutableArray *bundles = [NSMutableArray array];
    NSString *path = [self explandRootPathMacro:[setting searchDirectory] projectPath:project];
    NSArray* array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for(int i = 0; i<[array count]; i++){
        NSString *fullPath = [path stringByAppendingPathComponent:array[i]];
        NSError *error = nil;
        NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:&error];
        if ([attr[NSFileType] isEqualTo:NSFileTypeDirectory]) {
            if ([@"lproj" isEqualToString:fullPath.pathExtension]) {
                NSString *filePath = [fullPath stringByAppendingPathComponent:setting.searchTableName];
                BOOL isDir = NO;
                if([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] && !isDir){
                    [bundles addObject:fullPath];
                }
            }
        }
    }
    return [NSArray arrayWithArray:bundles];
}

+ (NSString*)settingFilePathByProjectName:(NSString*)projectName{
    NSString* settingDirectory = [StringModel _settingDirectory];
    NSString* fileName = [projectName length] ? projectName : @"Test.xcodeproj";
    return [settingDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", fileName]];
}

+ (StringSetting*)projectSettingByProjectName:(NSString*)projectName{
    static NSMutableDictionary* projectName2ProjectSetting = nil;
    if (projectName2ProjectSetting == nil) {
        projectName2ProjectSetting = [[NSMutableDictionary alloc] init];
    }
    if (projectName != nil) {
        id object = [projectName2ProjectSetting objectForKey:projectName];
        if ([object isKindOfClass:[StringSetting class]]) {
            return object;
        }
    }
    
    NSString* fullPath = [StringModel settingFilePathByProjectName:projectName];
    StringSetting* projectSetting = nil;
    if([[NSFileManager defaultManager] fileExistsAtPath:fullPath]){
        @try {
            projectSetting = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
        }
        @catch (NSException* exception)
        {
            NSLog(@"读取失败 exception %@",exception);
            projectSetting = nil;
        }
    }
    
    if ([projectSetting isKindOfClass:[projectSetting class]] == NO) {
        projectSetting = nil;
    }
    
    if (projectSetting == nil) {
        NSLog(@"重新生成");
        projectSetting = [StringSetting defaultSettingWithProject:projectName];
    }
    if ((projectSetting != nil) && (projectName != nil)) {
        [projectName2ProjectSetting setObject:projectSetting forKey:projectName];
    }
    return projectSetting;
}

+ (void)saveProjectSetting:(StringSetting*)projectSetting ByProjectName:(NSString*)projectName{
    if (projectSetting == nil)
        return;
    NSString* filePath = [StringModel settingFilePathByProjectName:projectName];
    @try {
        NSLog(@"save %@ %@",projectSetting.includeDirs, projectSetting.excludeDirs);
        [NSKeyedArchiver archiveRootObject:projectSetting toFile:filePath];
        filePath = nil;
    }
    @catch (NSException* exception)
    {
         NSLog(@"saveProjectSetting:exception:%@", exception);
    }
}

@end

@implementation ActionModel

-(NSString*)description {
    return [NSString stringWithFormat:@"%ld %@ %@ %@",_actionType, _identifier, _key, _value];
}

@end

@implementation StringItem

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@:%ld:%@",self.filePath,self.lineNumber,self.content];
}

@end