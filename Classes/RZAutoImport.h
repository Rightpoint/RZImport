//
//  RZAutoImport.h
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/21/14.
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


#import <Foundation/Foundation.h>
#import "RZAutoImportable.h"

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
 *  Optionally implement @p RZAutoImportable on the object class to manage
 *  object uniqueness, relationships, and other configuration options.
 *
 *  Inferred mappings are cached for performance when repeatedly importing the
 *  same type of object. If performance is a major concern, you can always implement
 *  the RZAutoImportable protocol and provide a pre-defined mapping.
 */
@interface NSObject (RZAutoImport)

/**
 *  Return an instance of the calling class initialized with the values in the dictionary.
 *
 *  If the calling class implements RZAutoImportable, it is given the opportunity
 *  to return an existing unique instance of the object that is represented by
 *  the dictionary.
 *
 *  @param dict Dictionary from which to create the object instance.
 *
 *  @return An object instance initialized with the values in the dictionary.
 */
+ (instancetype)rzai_objectFromDictionary:(NSDictionary *)dict;

/**
 *  Return an array of instances of the calling class initialized with the
 *  values in the dicitonaries in the provided array.
 *
 *  The array parameter should contain only @p NSDictionary instances.
 *
 *  If the calling class implements RZAutoImportable, it is given the opportunity
 *  to return an existing unique instance of an object that is represented by
 *  each dictionary.
 *
 *  @param array An array of @p NSDictionary instances objects to import.
 *
 *  @return An array of objects initiailized with the respective values in each dictionary in the array.
 */
+ (NSArray *)rzai_objectsFromArray:(NSArray *)array;
 
/**
 *  Import the values from the provided dictionary into this object.
 *  Uses the implicit key/property mapping and the optional mapping overrides
 *  provided by RZAutoImportable.
 *
 *  @param dict Dictionary of values to import.
 */
- (void)rzai_importValuesFromDict:(NSDictionary *)dict;

/**
 *  The dictionary of inferred and overriden key/property mappings for this class
 *
 *  @return A dictionary of key/property mappings.
 */
+ (NSDictionary *)rzai_importMapping;

@end
