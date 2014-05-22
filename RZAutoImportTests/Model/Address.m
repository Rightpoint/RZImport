//
// Created by Nick Donaldson on 5/22/14.
//

#import "Address.h"

NSString* const kAddressLastUpdatedFormat = @"yyyy-MM-dd_HH:mm";

@implementation Address

+ (NSDictionary *)rzai_customKeyMappings
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

@end