//
//  StringModel.h
//  StringManage
//
//  Created by kiwik on 1/13/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ActionModel;
@interface StringModel : NSObject

@property (nonatomic, strong) NSString *path;//lproj路径
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *identifier;//国家
@property (nonatomic, strong) NSMutableDictionary *stringDictionary;//字符串字典

-(void)doAction:(NSArray*)actions;

- (instancetype)initWithPath:(NSString*)path;

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
