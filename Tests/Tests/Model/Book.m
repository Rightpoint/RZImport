//
//  Book.m
//  RZImportTests
//
//  Created by Bradley Smith on 12/9/15.
//
//

#import "Book.h"

@implementation Book

+ (id)rzi_existingObjectForDict:(NSDictionary *)dict
{
    NSString *title = dict[@"title"];
    Book *book = nil;

    if ([title isEqualToString:@"Title 1"]) {
        book = [[Book alloc] initWithID:@(12345)];
    }

    return book;
}

- (BOOL)rzi_shouldImportValuesFromDict:(NSDictionary *)dict withMappings:(NSDictionary *)mappings
{
    NSString *category = dict[@"category"];

    return [category isEqualToString:@"mystery"];
}

- (void)rzi_didImportValuesFromDict:(NSDictionary *)dict withMappings:(NSDictionary *)mappings {
    self.subtitle = self.title;
}

@end
