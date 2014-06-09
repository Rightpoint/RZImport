//
//  NSObject+RZAutoImport_Private.h
//  RZAutoImportTests
//
//  Created by Nick Donaldson on 6/9/14.
//
//  Copyright 2014 Raizlabs and other contributors
//  http://raizlabs.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

/**
 *  Private category methods, enums, and utility classes.
 *  NOT INTENDED FOR PUBLIC USAGE.
 */

@import Foundation;

/**
 *  These are merely the data types the importer can manage.
 *  Unknown data types for matching keys will log an error if automatic conversion
 *  is not possible.
 */
typedef NS_ENUM(NSInteger, RZAutoImportDataType)
{
    RZAutoImportDataTypeUnknown = -1,
    RZAutoImportDataTypePrimitive = 0,
    RZAutoImportDataTypeNSNumber,
    RZAutoImportDataTypeNSString,
    RZAutoImportDataTypeNSDate,
    RZAutoImportDataTypeNSDictionary,
    RZAutoImportDataTypeNSArray
};

OBJC_EXTERN RZAutoImportDataType rzai_dataTypeFromString(NSString *string);

/**
 *  Returns a normalized verison of the key argument
 *  by removing all underscores and making lowercase.
 *
 *  @param key Key to normalize.
 *
 *  @return Normalized key.
 */
OBJC_EXTERN NSString *rzai_normalizedKey(NSString *key);

@interface NSObject (RZAutoImport_Private)

+ (NSDictionary *)rzai_importMapping;

@end

// ===============================================
//           Propery Info Class
// ===============================================

@interface RZAIPropertyInfo : NSObject

@property (nonatomic, copy)   NSString *propertyName;
@property (nonatomic, assign) RZAutoImportDataType dataType;

@end
