//
//  StringPathEditViewController
//  XToDo
//
//  Created by kiwik on 1/16/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import <AppKit/AppKit.h>
typedef NS_ENUM(NSInteger, PathEditType) {
    PathEditTypeInclude,
    PathEditTypeExclude,
    PathEditTypeLocalizable,
    PathEditTypeExtension,
};

@interface StringPathEditViewController : NSViewController <NSTableViewDataSource>
- (id)initWithArray:(NSArray*)array;
@property NSMutableArray* array;
@property (nonatomic, assign) PathEditType pathEditType;
@end