//
//  RZImportable.h
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/21/14.
//
//

#import <Foundation/Foundation.h>

@protocol RZImportable <NSObject>

@optional

/**
 *  Provide a dictionary of custom mappings from dictionary keys to properties.
 *
 *  @return A dictionary containing mappings from dictionary keys to property names.
 */
+ (NSDictionary *)rz_customKeyMappings;

/**
 *  Gives the model class the opportunity to return an existing object 
 *  for the provided dictionary representation. Use this method to manage
 *  object uniqueness.
 *
 *  @param dict Dictionary representation of object being imported.
 *
 *  @return An existing object instance represented by the dict, or nil if one does not exist.
 */
+ (instancetype)rz_existingObjectForDict:(NSDictionary *)dict;

@end
