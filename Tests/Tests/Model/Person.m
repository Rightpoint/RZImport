//
//  Person.m
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/21/14.
//
//

#import "Person.h"
#import "Address.h"
#import "TestDataStore.h"
#import "NSObject+RZAutoImport.h"

@implementation Person

+ (id)rzai_existingObjectForDict:(NSDictionary *)dict
{
    NSNumber *objID = [dict objectForKey:@"id"];
    if ( objID != nil ) {
        return [[TestDataStore sharedInstance] objectWithClassName:@"Person" forId:objID];
    }
    return nil;
}

- (BOOL)rzai_shouldImportValue:(id)value forKey:(NSString *)key
{
    if ( [key isEqualToString:@"address"] && [value isKindOfClass:[NSDictionary class]] ) {
        self.address = [Address rzai_objectFromDictionary:value];
        return NO;
    }
    return YES;
}

@end
