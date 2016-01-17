//
//  TestCoding.h
//  StringManage
//
//  Created by kiwik on 1/17/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StringSetting : NSObject<NSCoding>
@property (nonatomic , copy) NSString* searchDirectory;
@property (nonatomic , copy) NSString* searchTableName;
@property (nonatomic , copy) NSArray* searchTypes;
@property (nonatomic , copy) NSArray* includeDirs;
@property (nonatomic , copy) NSArray* excludeDirs;

+ (StringSetting*)defaultSettingWithProject:(NSString*)projectName;
@end
