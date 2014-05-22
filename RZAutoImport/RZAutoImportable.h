//
//  RZAutoImportable.h
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/21/14.
//
//

#import <Foundation/Foundation.h>

@protocol RZAutoImportable <NSObject>

@optional

/**
 *  Implement to provide dictionary of custom mappings from dictionary keys to properties.
 *
 *  @return A dictionary containing mappings from dictionary keys to property names.
 */
+ (NSDictionary *)rzai_customKeyMappings;

/**
 *  Implement to provide a custom date format string for a particular key or keys.
 *  Will only be called if the inferred property is an NSDate type and the dict value is a string.
 *
 *  @param key Unmodified key from the dictionary being imported.
 *
 *  @return A date format to use for importing this key, otherwise nil to use the default (ISO-8601).
 */
+ (NSString *)rzai_dateFormatForKey:(NSString *)key;

/**
 *  Implement to return an existing object for the provided dictionary representation. 
 *  Use this method to enforce object uniqueness.
 *
 *  @param dict Dictionary representation of object being imported.
 *
 *  @return An existing object instance represented by the dict, or nil if one does not exist.
 */
+ (id)rzai_existingObjectForDict:(NSDictionary *)dict;

/**
 *  Implement to optionally prevent import for particular key/value pairs.
 *  Can be used to validate imported value or override automatic import to perform custom logic.
 *
 *  @param value Unmodified value from dictionary being imported
 *  @param key   Unmodified key from dictionary being imported
 *
 *  @return YES if RZAutoImport should proceed with automatic import for the key/value pair
            NO if the key/value pair should not be imported or will be handled within this method.
 */
- (BOOL)rzai_shouldImportValue:(id)value forKey:(NSString *)key;

@end
