//
//  RZAutoImport.h
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/21/14.
//

#import <Foundation/Foundation.h>
#import "RZImportable.h"

/**
 *  Automatically map key/value pairs from dictionary to properties
 *  on an object instance. Handles correct type conversion when possible.
 *  
 *  This category is useful when deserializing model objects from webservice
 *  JSON responses, plists, or anything else that can be deserialized into a
 *  dictionary or array.
 *
 *  Automatic mapping will occur between keys and properties that are a case-insensitive
 *  string match, regardless of underscores. For example, a property named "lastName" will
 *  match any of the following keys in a provided dictionary:
 *  
 *  @code 
 *  @"lastName"
 *  @"lastname" 
 *  @"last_name" 
 *  @endcode
 *
 *  Optionally implement @p RZImportable on the object class to manage
 *  object uniqueness, relationships, and other configuration options.
 *
 *  Inferred mappings are cached for performance when repeatedly importing the
 *  same type of object. If performance is a major concern, you can always implement
 *  the RZImportable protocol and provide a pre-defined mapping.
 */
@interface NSObject (RZAutoImport)

/**
 *  Return an instance of the calling class initialized with the values in the dictionary.
 *
 *  If the calling class implements RZImportable, it is given the opportunity
 *  to return an existing unique instance of the object that is represented by
 *  the dictionary.
 *
 *  @param dict Dictionary from which to create the object instance.
 *
 *  @return An object instance initialized with the values in the dictionary.
 */
+ (instancetype)rz_objectFromDictionary:(NSDictionary *)dict;

/**
 *  Return an array of instances of the calling class initialized with the
 *  values in the dicitonaries in the provided array.
 *
 *  The array parameter should contain only @p NSDictionary instances.
 *
 *  If the calling class implements RZImportable, it is given the opportunity
 *  to return an existing unique instance of an object that is represented by
 *  each dictionary.
 *
 *  @param array An array of @p NSDictionary instances objects to import.
 *
 *  @return An array of objects initiailized with the respective values in each dictionary in the array.
 */
+ (NSArray *)rz_objectsFromArray:(NSArray *)array;
 
/**
 *  Import the values from the provided dictionary into this object.
 *  Uses the implicit key/property mapping and the optional mapping overrides
 *  provided by RZImportable.
 *
 *  @param dict Dictionary of values to import.
 */
- (void)rz_importValuesFromDict:(NSDictionary *)dict;


@end
