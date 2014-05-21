//
//  RZAutoImportTests.m
//  RZAutoImportTests
//
//  Created by Nick Donaldson on 5/21/14.
//
//

#import <XCTest/XCTest.h>

#import "RZAutoImport.h"
#import "Person.h"

extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));

@interface RZAutoImportTests : XCTestCase

@end

@implementation RZAutoImportTests

#pragma mark - Utility

- (id)loadTestJson:(NSString *)filename error:(NSError *__autoreleasing *)err;
{
    id    result   = nil;
    NSURL *fileURL = [[NSBundle bundleForClass:[self class]] URLForResource:filename withExtension:@"json"];
    if ( fileURL ) {
        NSData  *data = [NSData dataWithContentsOfURL:fileURL];
        result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:err];
    }
    return result;
}

#pragma mark - Tests

- (void)test_basicImport
{
    NSError      *err = nil;
    NSDictionary *d   = [self loadTestJson:@"test_basic" error:&err];
    XCTAssertNil(err, @"Error reading json: %@", err);
    XCTAssertNotNil(d, @"Could not deserialize json");
    
    Person *johndoe = nil;
    XCTAssertNoThrow(johndoe = [Person rz_objectFromDictionary:d], @"Import should not throw exception");
    XCTAssertNotNil(johndoe, @"Failed to create object");
    XCTAssertNotNil(johndoe.lastUpdated, @"Failed to import last updated");
    XCTAssertEqualObjects(johndoe.ID, @100, @"Failed to import ID");
    XCTAssertEqualObjects(johndoe.firstName, @"John", @"Failed to import first name");
    XCTAssertEqualObjects(johndoe.lastName, @"Doe", @"Failed to import last name");
}

- (void)test_keyPermutations
{
    
}

- (void)test_setNil
{
    NSDictionary *d = @{ @"firstName" : [NSNull null] };
    
    Person *johndoe = [Person new];
    johndoe.firstName = @"John";
    johndoe.lastName = @"Doe";
    
    XCTAssertNoThrow([johndoe rz_importValuesFromDict:d], @"Null value should not cause exception");
    XCTAssertNil(johndoe.firstName, @"Failed to set firstname to nil");
}

- (void)test_typeConversion
{
    
}

- (void)test_dateConversion
{
    
}

@end
