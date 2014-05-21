//
//  RZAutoImport.m
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/21/14.
//
//

#import "RZAutoImport.h"
#import <objc/runtime.h>

// ===============================================
//              Data Type Enumeration
// ===============================================

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
    RZAutoImportDataTypeNSDate
};

// ===============================================
//          Utility Macros and Functions
// ===============================================

#if ( DEBUG )
    #define RZAILogDebug(msg, ...) NSLog((@"[RZAutoImport : DEBUG] " msg), ##__VA_ARGS__)
#else
    #define RZAILogDebug(...)
#endif

#define RZAILogError(msg, ...) NSLog((@"[RZAutoImport : ERROR] " msg), ##__VA_ARGS__);

#define RZAINSNullToNil(x) ([x isEqual:[NSNull null]] ? nil : x)

static NSString * RZAINormalizedKey(NSString *key)
{
    if ( key == nil ) {
        return nil;
    }
    return [[key lowercaseString] stringByReplacingOccurrencesOfString:@"_" withString:@""];
}

static objc_property_t RZAIGetProperty( NSString *name, Class class ) {
    
    objc_property_t property = class_getProperty( class, [name UTF8String] );
    
    if ( property == NULL) {
        // check base classes
        Class baseClass = class_getSuperclass( class );
        while ( baseClass != Nil && property == NULL) {
            property  = class_getProperty( baseClass, [name UTF8String] );
            baseClass = class_getSuperclass( baseClass );
        }
    }
    
    return property;
}

static RZAutoImportDataType RZAIDataTypeForProperty( NSString *propertyName, Class aClass ) {
    
    objc_property_t property = RZAIGetProperty( propertyName, aClass );
    if ( property == nil ) {
        return RZAutoImportDataTypeUnknown;
    }
    
    char *typeEncoding = nil;
    typeEncoding = property_copyAttributeValue(property, "T");
    
    if ( typeEncoding == NULL ) {
        return RZAutoImportDataTypeUnknown;
    }
    
    RZAutoImportDataType type = RZAutoImportDataTypeUnknown;
    
    switch ( typeEncoding[0] ) {
            
        // Object class
        case '@': {
            NSString *typeString = [[NSString stringWithUTF8String:typeEncoding] substringFromIndex:1];
            
            if ( [typeString isEqualToString:@"NSString"]) {
                type = RZAutoImportDataTypeNSString;
            }
            else if ( [typeString isEqualToString:@"NSNumber"] ) {
                type = RZAutoImportDataTypeNSNumber;
            }
            else if ( [typeString isEqualToString:@"NSDate"] ) {
                type = RZAutoImportDataTypeNSDate;
            }
        }
            break;
            
        // Primitive type
        case 'c':
        case 'C':
        case 'i':
        case 'I':
        case 's':
        case 'S':
        case 'l':
        case 'L':
        case 'q':
        case 'Q':
        case 'f':
        case 'd':
        case 'B':
            type = RZAutoImportDataTypePrimitive;
            break;
            
        default:
            break;
    }
    
    if ( typeEncoding ) {
        free(typeEncoding), typeEncoding = NULL;
    }
    
    return type;
}

static NSArray* RZAIPropertyNamesForClass(Class aClass) {
    
    unsigned int    count;
    objc_property_t *properties = class_copyPropertyList( aClass, &count );
    
    NSMutableArray *names = [NSMutableArray array];
    
    for ( unsigned int i = 0; i < count; i++ ) {
        objc_property_t property      = properties[i];
        NSString        *propertyName = [NSString stringWithUTF8String:property_getName( property )];
        if ( propertyName ) {
            [names addObject:propertyName];
        }
    }
    
    if ( properties ) {
        free( properties ), properties = NULL;
    }
    
    return names;
}

static SEL RZAISetterForProperty(Class aClass, NSString *propertyName) {
    
    NSString        *setterString = nil;
    objc_property_t property      = RZAIGetProperty( propertyName, aClass );
    if ( property ) {
        char *setterCString = property_copyAttributeValue( property, "S" );
        
        if ( setterCString ) {
            setterString = [NSString stringWithUTF8String:setterCString];
            free( setterCString );
        }
        else {
            setterString = [NSString stringWithFormat:@"set%@:", [propertyName stringByReplacingCharactersInRange:NSMakeRange( 0, 1 ) withString:[[propertyName substringToIndex:1] capitalizedString]]];
        }
    }
    
    return setterString ? NSSelectorFromString( setterString ) : nil;
}

// ===============================================
//           Category Implementation
// ===============================================

@implementation NSObject (RZAutoImport)

#pragma mark - Static

+ (NSMutableDictionary *)s_rz_importMappingCache
{
    static NSMutableDictionary *s_importMappingCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_importMappingCache = [NSMutableDictionary dictionary];
    });
    return s_importMappingCache;
}

+ (NSSet *)s_rz_ignoredClasses
{
    static NSSet *s_ignoredClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_ignoredClasses = [NSSet setWithArray:@[
            @"NSObject",
            @"NSManagedObject"
        ]];
    });
    return s_ignoredClasses;
}

+ (NSLock *)s_rz_cacheLock
{
    static NSLock *s_cacheLock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_cacheLock      = [[NSLock alloc] init];
        s_cacheLock.name = @"com.raizlabs.autoImportCacheLock";
    });
    return s_cacheLock;
}

#pragma mark - Public

+ (instancetype)rz_objectFromDictionary:(NSDictionary *)dict
{
    NSParameterAssert(dict);
    
    id object = nil;
    
    if ( [self instancesRespondToSelector:@selector(rz_existingObjectForDict:)] ) {
        object = [[self class] rz_existingObjectForDict:dict];
    }
    
    if ( object == nil ) {
        object = [[self alloc] init];
    }
    
    [object rz_importValuesFromDict:dict];
    
    return object;
}

+ (NSArray *)rz_objectsFromArray:(NSArray *)array
{
    NSParameterAssert(array);
    
    NSMutableArray *objects = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSAssert([obj isKindOfClass:[NSDictionary class]], @"Array passed to rz_objectsFromArray: must only contain NSDictionary instances");
        if ( [obj isKindOfClass:[NSDictionary class]] ) {
            id importedObj = [self rz_objectFromDictionary:obj];
            if ( importedObj ) {
                [objects addObject:importedObj];
            }
        }
    }];
    
    return [NSArray arrayWithArray:objects];
}

- (void)rz_importValuesFromDict:(NSDictionary *)dict
{
    BOOL hasCustomImportBlocks = [self respondsToSelector:@selector(rz_customImportBlockForKey:)];
    
    NSDictionary *importMapping = [[self class] rz_importMapping];
    
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        
        if ( hasCustomImportBlocks ) {
            RZImportableCustomImportBlock block = [(id<RZImportable>)self rz_customImportBlockForKey:key];
            if ( block ) {
                block( key );
                return;
            }
        }
        
        NSString *propName = [importMapping objectForKey:RZAINormalizedKey(key)];
        value = RZAINSNullToNil(value);
        
        if ( propName ) {
            @try {
                if ( value == nil ) {
                    [self rz_setNilForPropertyNamed:propName];
                }
                else {
                    [self setValue:value forKey:propName];
                }
            }
            @catch ( NSException *exception ) {
                RZAILogError(@"Could not set value %@ for property %@ of class %@", value, propName, NSStringFromClass([self class]));
            }
        }
        else {
            RZAILogDebug(@"No property found in class %@ for key %@", NSStringFromClass([self class]), key);
        }
    }];
}

#pragma mark - Private

+ (NSDictionary *)rz_importMapping
{
    [[[self class] s_rz_cacheLock] lock];
    
    NSString *className = NSStringFromClass(self);
    
    NSMutableDictionary *mapping = [[[self class] s_rz_importMappingCache] objectForKey:className];
    if ( mapping == nil ) {
        
        mapping = [NSMutableDictionary dictionary];
        
        // Get mappings from the normalized property names
        [mapping addEntriesFromDictionary:[self rz_normalizedPropertyMappings]];
        
        // Get any mappings from the RZImportable protocol
        if ( [[self class] instancesRespondToSelector:@selector(rz_customKeyMappings)] ) {
            [mapping addEntriesFromDictionary:[[self class] rz_customKeyMappings]];
        }
        
        [[[self class] s_rz_importMappingCache] setObject:mapping forKey:className];
    }

    [[[self class] s_rz_cacheLock] unlock];
    
    return [NSDictionary dictionaryWithDictionary:mapping];
}

+ (NSDictionary *)rz_normalizedPropertyMappings
{
    NSMutableDictionary *mappings = [NSMutableDictionary dictionary];
    
    // Get property names from this class and all inherited classes
    NSMutableArray *propNames = [NSMutableArray array];
    Class currentClass = [self class];
    while ( currentClass != Nil ) {
        
        NSString *className = NSStringFromClass(currentClass);
        if ( ![[[self class] s_rz_ignoredClasses] containsObject:className] ) {
            [propNames addObjectsFromArray:RZAIPropertyNamesForClass(currentClass)];
        }
        currentClass = class_getSuperclass( currentClass );
    }
    
    [propNames enumerateObjectsUsingBlock:^(NSString *propName, NSUInteger idx, BOOL *stop) {
        [mappings setObject:propName forKey:RZAINormalizedKey(propName)];
    }];
    
    return [NSDictionary dictionaryWithDictionary:mappings];
}

- (void)rz_setNilForPropertyNamed:(NSString *)propName
{
    SEL setter = RZAISetterForProperty([self class], propName);
    if ( setter == nil ) {
        RZAILogError(@"Setter not available for property named %@", propName);
        return;
    }
    
    NSMethodSignature *methodSig  = [self methodSignatureForSelector:setter];
    NSInvocation      *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
    
    [invocation setTarget:self];
    [invocation setSelector:setter];
    
    // The buffer is copied so this is OK even though it will go out of scope
    id nilValue = nil;
    [invocation setArgument:&nilValue atIndex:2];
    [invocation invoke];
}

@end
