//
//  NSData+Split.h
//
//  Created by kiwik on 1/16/16.
//  Copyright © 2016 Kiwik. All rights reserved.
//

#import <Foundation/Foundation.h>

/// An NSData category that allows splitting the data into separate components.

@interface NSData (Split)

/** Splits the source data into any array of components separated by the specified byte.
 
 Taken from http://www.geektheory.ca/blog/splitting-nsdata-object-data-specific-byte/
 
 @param sep Byte to separate by.
 @return NSArray of components
 */
- (NSArray*)componentsSeparatedByByte:(Byte)sep;

@end
