//
//  StringModel.m
//  StringManage
//
//  Created by kiwik on 1/13/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import "StringModel.h"

static NSString * const kRegularExpressionPattern = @"(\"(\\S+.*\\S+)\"|(\\S+.*\\S+))\\s*=\\s*\"(.*)\";$";

@implementation StringModel

- (instancetype)initWithPath:(NSString*)path
{
    self = [super init];
    if (self) {
        self.path = path;
        self.filePath = [path stringByAppendingPathComponent:@"Localizable.strings"];
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

-(void)doAction:(NSArray*)actions
{
    NSString *string = [NSString stringWithContentsOfFile:self.filePath usedEncoding:nil error:nil];
    
    NSMutableString *mutableString = [[NSMutableString alloc]initWithString:string];
    
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:kRegularExpressionPattern options:0 error:nil];
    
    for (ActionModel *action in actions)
    {
        if(![action.identifier isEqualToString:_identifier])
        {
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
            if (result.range.location != NSNotFound && result.numberOfRanges == 5)
            {
                keyRange = [result rangeAtIndex:2];
                
                if (keyRange.location == NSNotFound)
                {
                    keyRange = [result rangeAtIndex:3];
                }
                valueRange = [result rangeAtIndex:4];
                key = [line substringWithRange:keyRange];
                value = [line substringWithRange:valueRange];
            }
            
            if (key && value)
            {
                if([key isEqualToString:action.key])
                {
                    found = YES;
                    if(action.actionType == ActionTypeRemove)
                    {
                        NSLog(@"delete a line");
                        [mutableString deleteCharactersInRange:lineRange];
                    }
                    else
                    {
                        NSLog(@"modify a value");
                        valueRange.location += lineOffset;
                        [mutableString deleteCharactersInRange:valueRange];
                        [mutableString insertString:action.value atIndex:valueRange.location];
                    }
                    *stop = YES;
                }
            }
            
            lineOffset += lineRange.length;
        }];
        if(!found && action.actionType == ActionTypeAdd)
        {
            [mutableString appendFormat:@"\n\"%@\"=\"%@\";",action.key, action.value];
        }
    }
    
    NSLog(@"mutableString %@",mutableString);
    //write to filepath
    NSError *error = nil;
    BOOL result = [mutableString writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if(!result)
    {
        NSLog(@"failed to save %@",[error description]);
    }
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"path %@\n filePath %@\n identifier %@\n stringDictionary %@",_path,_filePath,_identifier,_stringDictionary];
}

@end

@implementation ActionModel

-(NSString*)description
{
    return [NSString stringWithFormat:@"%ld %@ %@ %@",_actionType, _identifier, _key, _value];
}

@end
