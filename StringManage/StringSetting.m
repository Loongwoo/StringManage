//
//  TestCoding.m
//  StringManage
//
//  Created by kiwik on 1/17/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "StringSetting.h"
#import "StringModel.h"

@implementation StringSetting

+ (StringSetting*)defaultSettingWithProject:(NSString*)projectName {
    NSString *name = [projectName stringByDeletingPathExtension];
    StringSetting* projectSetting = [[StringSetting alloc] init];
    projectSetting.searchDirectory = [StringModel addPathSlash:[[StringModel rootPathMacro] stringByAppendingPathComponent:name]];
    projectSetting.searchTableName = @"Localizable.strings";
    projectSetting.searchTypes = @[@"h", @"m",@"swift",@"mm"];
    projectSetting.includeDirs = @[ [StringModel rootPathMacro] ];
    projectSetting.excludeDirs = @[ [StringModel addPathSlash:[[StringModel rootPathMacro] stringByAppendingPathComponent:@"Pods"]], [StringModel addPathSlash:[[StringModel rootPathMacro] stringByAppendingPathComponent:@"Carthage"]] ];
    return projectSetting;
}

#pragma mark - Archiving

static NSString *searchDirectory = @"searchDirectory";
static NSString *searchTableName = @"searchTableName";
static NSString *searchTypes = @"searchTypes";
static NSString *includeDirs = @"includeDirs";
static NSString *excludeDirs = @"excludeDirs";

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _searchDirectory = [aDecoder decodeObjectForKey:searchDirectory];
        _searchTableName = [aDecoder decodeObjectForKey:searchTableName];
        _searchTypes = [aDecoder decodeObjectForKey:searchTypes];
        _includeDirs = [aDecoder decodeObjectForKey:includeDirs];
        _excludeDirs = [aDecoder decodeObjectForKey:excludeDirs];
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
}

@end
