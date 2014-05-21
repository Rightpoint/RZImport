//
//  RZImportable.h
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/21/14.
//
//

#import <Foundation/Foundation.h>

typedef void (^RZImportableCustomImportBlock)(id value);

@protocol RZImportable <NSObject>

@optional

/**
 *  Implement to provide dictionary of custom mappings from dictionary keys to properties.
 *
 *  @return A dictionary containing mappings from dictionary keys to property names.
 */
+ (NSDictionary *)rz_customKeyMappings;

/**
 *  Implement to return an existing object for the provided dictionary representation. 
 *  Use this method to enforce object uniqueness.
 *
 *  @param dict Dictionary representation of object being imported.
 *
 *  @return An existing object instance represented by the dict, or nil if one does not exist.
 */
+ (instancetype)rz_existingObjectForDict:(NSDictionary *)dict;

/**
 *  Implement to optionally provide a custom import block for a given key in the dictionary
 *  being imported.
 *
 *  The returned block is NOT retained - it is totally safe to use @p self within the block.
 *
 *  @param key Key in dictionary being imported.
 *
 *  @return An import block that will be used to import the value for the given key, or nil
 *          if the given key does not need a custom import block.
 */
- (RZImportableCustomImportBlock)rz_customImportBlockForKey:(NSString *)key;

@end
