//
//  TestCoding.h
//  StringManage
//
//  Created by kiwik on 1/17/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    StringLanguageObjC,
    StringLanguageSwift,
} StringLanguage;

@interface StringSetting : NSObject<NSCoding>
@property (nonatomic , copy) NSString* searchDirectory;
@property (nonatomic , copy) NSString* searchTableName;
@property (nonatomic , copy) NSString* doubleClickWrapper;
@property (nonatomic , copy) NSArray* searchTypes;
@property (nonatomic , copy) NSArray* includeDirs;
@property (nonatomic , copy) NSArray* excludeDirs;
@property (nonatomic , assign) NSInteger language;
@property (nonatomic , assign) NSInteger maxOperationCount;

+ (StringSetting*)defaultSettingWithProjectPath:(NSString *)projectPath projectName:(NSString*)projectName;
@end
