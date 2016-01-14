//
//  ProjectSetting
//  XToDo
//
//  Created by shuice on 2014-03-08.
//  Copyright (c) 2014. All rights reserved.
//

#import <AppKit/AppKit.h>

extern NSString* const kSearchDirectory;
extern NSString* const kSearchTableName;
extern NSString* const kNotifyProjectSettingChanged;

@interface ProjectSetting : NSObject

@property NSString* searchDirectory;
@property NSString* projectName;
@property NSString* searchTableName;

+(instancetype)shareInstance;

-(NSString *)settingName;

- (void) save;

@end