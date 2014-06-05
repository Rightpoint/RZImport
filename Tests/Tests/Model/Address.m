//
// Created by Nick Donaldson on 5/22/14.
//

#import "Address.h"

NSString* const kAddressLastUpdatedFormat = @"yyyy-MM-dd_HH:mm";

@implementation Address

+ (NSDictionary *)rzai_customMappings
{
    return @{
        @"street" : @"street1",
        @"zip" : @"zipCode"
    };
}

+ (NSString *)rzai_dateFormatForKey:(NSString *)key
{
    if ( [key isEqualToString:@"last_updated"] ) {
        return kAddressLastUpdatedFormat;
    }
    return nil;
}

- (BOOL)rzai_shouldImportValue:(id)value forKey:(NSString *)key
{
    if ( [key isEqualToString:@"zip"] ) {
        // validation - must be a string that only contains numbers
        if ( [value isKindOfClass:[NSString class]] ) {
            return ([value rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location == NSNotFound);
        }
        return NO;
    }
    return YES;
}

@end
