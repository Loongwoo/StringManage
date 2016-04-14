//
//  TestCoding.m
//  StringManage
//
//  Created by kiwik on 1/17/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "StringSetting.h"
#import "StringModel.h"
#import "NSString+Extension.h"

@implementation StringSetting

+ (StringSetting*)defaultSettingWithProjectPath:(NSString *)projectPath projectName:(NSString*)projectName {
    NSString *name = [projectName stringByDeletingPathExtension];
    StringSetting* projectSetting = [[StringSetting alloc] init];
    projectSetting.searchDirectory = [StringModel addPathSlash:[[StringModel rootPathMacro] stringByAppendingPathComponent:name]];
    projectSetting.searchTableName = @"Localizable.strings";
    projectSetting.searchTypes = @[@"h", @"m",@"swift",@"mm",@"pch"];
    projectSetting.includeDirs = @[ [StringModel rootPathMacro] ];
    projectSetting.excludeDirs = @[
                                   [StringModel addPathSlash:[[StringModel rootPathMacro] stringByAppendingPathComponent:@"Pods"]],
                                   [StringModel addPathSlash:[[StringModel rootPathMacro] stringByAppendingPathComponent:@"Carthage"]],
                                   [StringModel addPathSlash:[[StringModel rootPathMacro] stringByAppendingPathComponent:@"DerivedData"]]
                                   ];
    NSInteger language = [StringModel devLanguageWithProjectPath:projectPath];
    projectSetting.language = language;
    if (language == StringLanguageSwift) {
        //key will be replace with "value"
        projectSetting.doubleClickWrapper = @"NSLocalizedString(key, comment: "")";
    }else{
        //key will be replace with @"value"
        projectSetting.doubleClickWrapper = @"NSLocalizedString(key, nil)";
    }
    projectSetting.maxOperationCount = 5;
    return projectSetting;
}

#pragma mark - Archiving

static NSString *searchDirectory = @"searchDirectory";
static NSString *searchTableName = @"searchTableName";
static NSString *searchTypes = @"searchTypes";
static NSString *includeDirs = @"includeDirs";
static NSString *excludeDirs = @"excludeDirs";
static NSString *language = @"language";
static NSString *doubleClickWrapper = @"doubleClickWrapper";
static NSString *maxOperationCount = @"maxOperationCount";

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _searchDirectory = [aDecoder decodeObjectForKey:searchDirectory];
        _searchTableName = [aDecoder decodeObjectForKey:searchTableName];
        _searchTypes = [aDecoder decodeObjectForKey:searchTypes];
        _includeDirs = [aDecoder decodeObjectForKey:includeDirs];
        _excludeDirs = [aDecoder decodeObjectForKey:excludeDirs];
        _language = [aDecoder decodeIntegerForKey:language];
        _doubleClickWrapper = [aDecoder decodeObjectForKey:doubleClickWrapper];
        _maxOperationCount = [aDecoder decodeIntegerForKey:maxOperationCount];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)aCoder
{
    [aCoder encodeObject:self.searchDirectory ? self.searchDirectory : @"" forKey:searchDirectory];
    [aCoder encodeObject:self.searchTableName ? self.searchTableName : @"" forKey:searchTableName];
    [aCoder encodeObject:self.searchTypes ? self.searchTypes : @[] forKey:searchTypes];
    [aCoder encodeObject:self.includeDirs ? self.includeDirs : @[] forKey:includeDirs];
    [aCoder encodeObject:self.excludeDirs ? self.excludeDirs : @[] forKey:excludeDirs];
    [aCoder encodeInteger:self.language forKey:language];
    [aCoder encodeObject:self.doubleClickWrapper ? self.doubleClickWrapper : @"" forKey:doubleClickWrapper];
    [aCoder encodeInteger:self.maxOperationCount forKey:maxOperationCount];
}

-(NSInteger)language{
    if (_language < 0 || _language > 1) {
        _language = 0;
    }
    return _language;
}

-(NSString*)doubleClickWrapper{
    if (!_doubleClickWrapper) {
        if (_language == StringLanguageSwift) {
            //key will be replace with "value"
            _doubleClickWrapper = @"NSLocalizedString(key, comment: "")";
        }else{
            //key will be replace with @"value"
            _doubleClickWrapper = @"NSLocalizedString(key, nil)";
        }
    }
    return _doubleClickWrapper;
}

-(NSInteger)maxOperationCount{
    if (_maxOperationCount<=0 || _maxOperationCount>10) {
        _maxOperationCount = 5;
    }
    return _maxOperationCount;
}


@end
