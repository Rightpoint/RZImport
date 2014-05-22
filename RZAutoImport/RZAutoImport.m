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
//            Constants and Enums
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

static NSString* const kRZAutoImportISO8601DateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";

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
            
            NSUInteger typeLength = (NSUInteger)strlen(typeEncoding);
            
            if ( typeLength > 3 ) {
                
                NSString *typeString = [[NSString stringWithUTF8String:typeEncoding] substringWithRange:NSMakeRange(2, typeLength - 3)];
                
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
//           Propery Descriptor Class
// ===============================================

@interface RZAIPropertyDescriptor : NSObject

@property (nonatomic, copy)   NSString *propertyName;
@property (nonatomic, assign) RZAutoImportDataType dataType;

@end

@implementation RZAIPropertyDescriptor
@end

// ===============================================
//           Category Implementation
// ===============================================

@implementation NSObject (RZAutoImport)

#pragma mark - Static

+ (NSMutableDictionary *)s_rzai_importMappingCache
{
    static NSMutableDictionary *s_importMappingCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_importMappingCache = [NSMutableDictionary dictionary];
    });
    return s_importMappingCache;
}

+ (NSSet *)s_rzai_ignoredClasses
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

+ (NSNumberFormatter *)s_rzai_numberFormatter
{
    static NSNumberFormatter *s_numberFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_numberFormatter = [[NSNumberFormatter alloc] init];
        s_numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        
        // !!!: The locale is mandated to be US, so JSON API responses will parse correctly regardless of locality.
        //      If other localization is required, custom import blocks must be used.
        s_numberFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    });
    return s_numberFormatter;
}

+ (NSDateFormatter *)s_rzai_dateFormatter
{
    static NSDateFormatter *s_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.dateFormat = kRZAutoImportISO8601DateFormat;
        
        // !!!: The time zone is mandated to be GMT for parsing string dates.
        //      Any timezone offsets should be encoded into the date string or handled on the display level.
        s_dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        
        // !!!: The locale is mandated to be US, so JSON API responses will parse correctly regardless of locality.
        //      If other localization is required, custom import blocks must be used.
        s_dateFormatter.locale   = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    });
    return s_dateFormatter;
}

/**
 *  Recursive mutex lock used for resource contention.
 *  Custom import blocks may call into this category so the lock
 *  must be recursive in order to support recursive accesses on 
 *  the same thread within the same stack frame.
 */
+ (NSRecursiveLock *)s_rzai_mutex
{
    static NSRecursiveLock *s_mutex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_mutex = [[NSRecursiveLock alloc] init];
    });
    return s_mutex;
}

#pragma mark - Public

+ (instancetype)rzai_objectFromDictionary:(NSDictionary *)dict
{
    NSParameterAssert(dict);
    
    id object = nil;
    
    if ( [self respondsToSelector:@selector( rzai_existingObjectForDict: )] ) {
        Class <RZAutoImportable> thisClass = [self class];
        object = [thisClass rzai_existingObjectForDict:dict];
    }
    
    if ( object == nil ) {
        object = [[self alloc] init];
    }

    [object rzai_importValuesFromDict:dict];
    
    return object;
}

+ (NSArray *)rzai_objectsFromArray:(NSArray *)array
{
    NSParameterAssert(array);
    
    NSMutableArray *objects = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSAssert([obj isKindOfClass:[NSDictionary class]], @"Array passed to rzai_objectsFromArray: must only contain NSDictionary instances");
        if ( [obj isKindOfClass:[NSDictionary class]] ) {
            id importedObj = [self rzai_objectFromDictionary:obj];
            if ( importedObj ) {
                [objects addObject:importedObj];
            }
        }
    }];
    
    return [NSArray arrayWithArray:objects];
}

- (void)rzai_importValuesFromDict:(NSDictionary *)dict
{
    BOOL hasCustomImportBlocks = [self respondsToSelector:@selector( rzai_customImportBlockForKey:value: )];
    
    NSDictionary *importMapping = [[self class] rzai_importMapping];
    
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        
        if ( hasCustomImportBlocks ) {
            RZAutoImportableCustomImportBlock block = [(id <RZAutoImportable>)self rzai_customImportBlockForKey:key value:value];
            if ( block ) {
                block( key );
                return;
            }
        }
        
        RZAIPropertyDescriptor *propDescriptor = [importMapping objectForKey:RZAINormalizedKey(key)];
        value = RZAINSNullToNil(value);
        
        if ( propDescriptor ) {
            [self rzai_setValue:value fromKey:key forPropertyDescriptor:propDescriptor];
        }
        else {
            RZAILogDebug(@"No property found in class %@ for key %@. Create a custom mapping to import a value for this key.", NSStringFromClass([self class]), key);
        }
    }];
}

#pragma mark - Private

+ (void)rzai_performBlockAtomically:(void(^)())block
{
    [[self s_rzai_mutex] lock];
    if ( block ) {
        block();
    }
    [[self s_rzai_mutex] unlock];
}

+ (NSDictionary *)rzai_importMapping
{
    __block NSDictionary *returnMapping = nil;

    [self rzai_performBlockAtomically:^{

        NSString            *className = NSStringFromClass( self );
        NSMutableDictionary *mapping   = [[[self class] s_rzai_importMappingCache] objectForKey:className];

        if ( mapping == nil ) {

            mapping = [NSMutableDictionary dictionary];

            // Get mappings from the normalized property names
            [mapping addEntriesFromDictionary:[self rzai_normalizedPropertyMappings]];

            // Get any mappings from the RZAutoImportable protocol
            if ( [[self class] respondsToSelector:@selector( rzai_customKeyMappings )] ) {
                
                Class <RZAutoImportable> thisClass = [self class];
                NSDictionary *customMappings = [thisClass rzai_customKeyMappings];
                
                [customMappings enumerateKeysAndObjectsUsingBlock:^( NSString *keyname, NSString *propName, BOOL *stop ) {
                    RZAIPropertyDescriptor *propDescriptor = [[RZAIPropertyDescriptor alloc] init];
                    propDescriptor.propertyName = propName;
                    propDescriptor.dataType = RZAIDataTypeForProperty( propName, self );
                    [mapping setObject:propDescriptor forKey:RZAINormalizedKey( keyname )];
                }];
            }

            [[[self class] s_rzai_importMappingCache] setObject:mapping forKey:className];
        }

        returnMapping = [NSDictionary dictionaryWithDictionary:mapping];
    }];
    
    return returnMapping;
}

+ (NSDictionary *)rzai_normalizedPropertyMappings
{
    NSMutableDictionary *mappings = [NSMutableDictionary dictionary];
    
    // Get property names from this class and all inherited classes
    NSMutableArray *propDescriptors = [NSMutableArray array];

    Class currentClass = [self class];
    while ( currentClass != Nil ) {
        
        NSString *className = NSStringFromClass(currentClass);
        
        if ( ![[[self class] s_rzai_ignoredClasses] containsObject:className] ) {
            NSArray *classPropNames = RZAIPropertyNamesForClass(currentClass);
            [classPropNames enumerateObjectsUsingBlock:^(NSString *classPropName, NSUInteger idx, BOOL *stop) {
                RZAIPropertyDescriptor *propDescriptor = [[RZAIPropertyDescriptor alloc] init];
                propDescriptor.propertyName = classPropName;
                propDescriptor.dataType = RZAIDataTypeForProperty(classPropName, self);
                [propDescriptors addObject:propDescriptor];
            }];
        }
        
        currentClass = class_getSuperclass( currentClass );
    }
    
    [propDescriptors enumerateObjectsUsingBlock:^(RZAIPropertyDescriptor *propDescriptor, NSUInteger idx, BOOL *stop) {
        [mappings setObject:propDescriptor forKey:RZAINormalizedKey(propDescriptor.propertyName)];
    }];
    
    return [NSDictionary dictionaryWithDictionary:mappings];
}

- (void)rzai_setNilForPropertyNamed:(NSString *)propName
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

- (void)rzai_setValue:(id)value fromKey:(NSString *)originalKey forPropertyDescriptor:(RZAIPropertyDescriptor *)propDescriptor
{
    @try {
        if ( value == nil ) {
            [self rzai_setNilForPropertyNamed:propDescriptor.propertyName];
        }
        else {
            
            id convertedValue = nil;
            
            if ( [value isKindOfClass:[NSNumber class]] ) {
              
                switch (propDescriptor.dataType) {

                    case RZAutoImportDataTypeNSNumber:
                    case RZAutoImportDataTypePrimitive:
                        convertedValue = value;
                        break;

                    case RZAutoImportDataTypeNSString:
                        convertedValue = [value stringValue];
                        break;
                        
                    case RZAutoImportDataTypeNSDate: {
                        // Assume it's a unix timestamp
                        convertedValue = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
                        
                        RZAILogDebug(@"Received a number for key [%@] matching property [%@] of class [%@]. Assuming unix timestamp.",
                                     originalKey,
                                     propDescriptor.propertyName,
                                     NSStringFromClass([self class]));
                    }
                        break;
                        
                    default:
                        break;
                }
                
            }
            else if ( [value isKindOfClass:[NSString class]] ) {
                
                switch (propDescriptor.dataType) {

                    case RZAutoImportDataTypePrimitive:
                    case RZAutoImportDataTypeNSNumber: {
                        __block NSNumber *number = nil;
                        [[self class] rzai_performBlockAtomically:^{
                            number = [[[self class] s_rzai_numberFormatter] numberFromString:value];
                        }];
                        convertedValue = number;
                    }
                        break;
                        
                    case RZAutoImportDataTypeNSString:
                        convertedValue = value;
                        break;
                        
                    case RZAutoImportDataTypeNSDate: {
                        // Check for a date format from the object. If not provided, use ISO-8601.
                        __block NSDate *date = nil;
                        [[self class] rzai_performBlockAtomically:^{

                            NSString        *dateFormat     = nil;
                            NSDateFormatter *dateFormatter  = [[self class] s_rzai_dateFormatter];
                            
                            if ( [[self class] respondsToSelector:@selector(rzai_dateFormatForKey:)] ) {
                                Class <RZAutoImportable> thisClass = [self class];
                                dateFormat = [thisClass rzai_dateFormatForKey:originalKey];
                            }
                            
                            if ( dateFormat == nil ) {
                                dateFormat = kRZAutoImportISO8601DateFormat;
                            }
                            
                            dateFormatter.dateFormat = dateFormat;
                            date = [dateFormatter dateFromString:value];
                        }];
                        convertedValue = date;
                        
                    }
                        break;
                        
                    default:
                        break;
                }
                
            }
            else if ( [value isKindOfClass:[NSDate class]] ) {
                
                // This will not occur in raw JSON deserialization,
                // but the conversion may have already happened in an external method.
                if ( propDescriptor.dataType == RZAutoImportDataTypeNSDate ) {
                    convertedValue = value;
                }
            }
            
            if ( convertedValue ) {
                [self setValue:convertedValue forKey:propDescriptor.propertyName];
            }
            else {
                RZAILogError(@"Could not convert value of type [%@] from key [%@] to correct type for property [%@] of class [%@]",
                             NSStringFromClass([value class]),
                             originalKey,
                             propDescriptor.propertyName,
                             NSStringFromClass([self class]));
            }
        }
    }
    @catch ( NSException *exception ) {
        RZAILogError(@"Could not set value %@ for property %@ of class %@", value, propDescriptor.propertyName, NSStringFromClass([self class]));
    }
}

@end
