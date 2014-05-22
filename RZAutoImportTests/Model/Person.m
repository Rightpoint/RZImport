//
//  Person.m
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/21/14.
//
//

#import "Person.h"
#import "Address.h"
#import "RZAutoImport.h"

@implementation Person

- (RZAutoImportableCustomImportBlock)rzai_customImportBlockForKey:(NSString *)key value:(id)value
{
    if ( [key isEqualToString:@"address"] && [value isKindOfClass:[NSDictionary class]] ) {
        self.address = [Address rzai_objectFromDictionary:value];
    }
    return nil;
}

@end
