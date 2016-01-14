//
//  ProjectSetting
//  XToDo
//
//  Created by shuice on 2014-03-08.
//  Copyright (c) 2014. All rights reserved.
//

#import "ProjectSetting.h"
#import "IAWorkspace.h"

NSString* const kSearchDirectory = @"searchDirectory";
NSString* const kSearchTableName = @"searchTableName";
NSString* const kNotifyProjectSettingChanged = @"XToDo_NotifyProjectSettingChanged";

@implementation ProjectSetting

+(instancetype)shareInstance
{
    static dispatch_once_t pred;
    static ProjectSetting *instance = nil;
    dispatch_once(&pred, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(NSString *)settingName
{
    return [NSString stringWithFormat:@"String_Setting_For_%@",_projectName];
}

- (void) save
{
    NSDictionary *dict = @{kSearchDirectory : _searchDirectory, kSearchTableName: _searchTableName};
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:[self settingName]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyProjectSettingChanged object:nil];
}
@end
