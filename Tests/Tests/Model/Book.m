//
//  Book.m
//  RZImportTests
//
//  Created by Bradley Smith on 12/9/15.
//
//

#import "Book.h"

@implementation Book

+ (BOOL)rzi_shouldImportValuesFromDict:(NSDictionary *)dict withMappings:(NSDictionary *)mappings
{
    NSString *category = dict[@"category"];

    return [category isEqualToString:@"mystery"];
}

- (void)rzi_willImportValuesFromDict:(NSDictionary *)dict withMappings:(NSDictionary *)mappings
{
    self.altTitle = dict[@"title"];
}

- (void)rzi_didImportValuesFromDict:(NSDictionary *)dict withMappings:(NSDictionary *)mappings
{
    self.subtitle = self.title;
}

@end
