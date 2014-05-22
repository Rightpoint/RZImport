//
//  RZAutoImportable.h
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/21/14.
//
//

#import <Foundation/Foundation.h>

typedef void (^RZAutoImportableCustomImportBlock)(id value);

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
 *  Implement to optionally provide a custom import block for a given key in the dictionary
 *  being imported.
 *
 *  The returned block is NOT retained - it is totally safe to use @p self within the block.
 *
 *  @param key      Unmodified key from the dictionary being imported.
 *  @param value    Unmodified value from the dictionary being imported.
 *
 *  @return An import block that will be used to import the value for the given key, or nil
 *          if the given key does not need a custom import block.
 */
- (RZAutoImportableCustomImportBlock)rzai_customImportBlockForKey:(NSString *)key value:(id)value;

@end
