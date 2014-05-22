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

@property (nonatomic, strong) Person *testPerson;

@end

@implementation RZAutoImportTests

#pragma mark - Setup

- (void)setUp
{
    [super setUp];
    Person *johndoe = [Person new];
    johndoe.ID = @100;
    johndoe.lastUpdated = [NSDate date];
    johndoe.firstName = @"John";
    johndoe.lastName = @"Doe";
    self.testPerson = johndoe;
}

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
    NSDictionary *d   = [self loadTestJson:@"test_person" error:&err];
    XCTAssertNil(err, @"Error reading json: %@", err);
    XCTAssertNotNil(d, @"Could not deserialize json");
    
    Person *johndoe = nil;
    XCTAssertNoThrow(johndoe = [Person rzai_objectFromDictionary:d], @"Import should not throw exception");
    XCTAssertNotNil(johndoe, @"Failed to create object");
    XCTAssertNotNil(johndoe.lastUpdated, @"Failed to import last updated");
    XCTAssertEqualObjects(johndoe.ID, @100, @"Failed to import ID");
    XCTAssertEqualObjects(johndoe.firstName, @"John", @"Failed to import first name");
    XCTAssertEqualObjects(johndoe.lastName, @"Doe", @"Failed to import last name");
}

- (void)test_keyPermutations
{
    NSArray *keyPermutations = @[@"firstname", @"FirstName", @"first_name", @"First_Name"];
    
    for ( NSString *key in keyPermutations ) {
        NSDictionary *d = @{ key : key };
        XCTAssertNoThrow( [self.testPerson rzai_importValuesFromDict:d], @"Import should not throw exception");
        XCTAssertEqualObjects(self.testPerson.firstName, key, @"Permutation failed: %@", key);
    }
}

- (void)test_setNil
{
    NSDictionary *d = @{ @"firstName" : [NSNull null] };
    XCTAssertNoThrow( [self.testPerson rzai_importValuesFromDict:d], @"Null value should not cause exception");
    XCTAssertNil(self.testPerson.firstName, @"Failed to set firstname to nil");
}

- (void)test_typeConversion
{
    // convert string to number
    NSDictionary *d = @{ @"id" : @"666" };
    XCTAssertNoThrow( [self.testPerson rzai_importValuesFromDict:d], @"Null value should not cause exception");
    XCTAssertEqualObjects(self.testPerson.ID, @666, @"Failed to convert string to number during import");
}

- (void)test_dateConversion
{
    
}

@end
