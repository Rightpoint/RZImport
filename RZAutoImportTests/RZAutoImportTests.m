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
#import "Address.h"
#import "TestDataStore.h"

extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));

@interface RZAutoImportTests : XCTestCase

@property (nonatomic, strong) Person *testPerson;

@end

@implementation RZAutoImportTests

#pragma mark - Setup

- (void)setUp
{
    [super setUp];
    
    Person *johndoe = [[Person alloc] initWithID:@100];
    johndoe.lastUpdated = [NSDate date];
    johndoe.firstName = @"John";
    johndoe.lastName = @"Doe";
    self.testPerson = johndoe;
    
    [[TestDataStore sharedInstance] addObject:johndoe];
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
    XCTAssertNil( err, @"Error reading json: %@", err );
    XCTAssertNotNil( d, @"Could not deserialize json" );
    
    Person *johndoe = nil;
    XCTAssertNoThrow( johndoe = [Person rzai_objectFromDictionary:d], @"Import should not throw exception" );
    XCTAssertNotNil( johndoe, @"Failed to create object" );
    XCTAssert( [johndoe.lastUpdated isKindOfClass:[NSDate class]], @"Failed to import last updated" ); // accuracy of date import verified in another test
    XCTAssertEqualObjects( johndoe.ID, @12345, @"Failed to import ID" );
    XCTAssertEqualObjects( johndoe.firstName, @"John", @"Failed to import first name" );
    XCTAssertEqualObjects( johndoe.lastName, @"Doe", @"Failed to import last name" );
}

- (void)test_customImportBlock
{
    NSError      *err = nil;
    NSDictionary *d   = [self loadTestJson:@"test_person_address" error:&err];
    XCTAssertNil( err, @"Error reading json: %@", err );
    XCTAssertNotNil( d, @"Could not deserialize json" );
    
    Person *johndoe = nil;
    XCTAssertNoThrow( johndoe = [Person rzai_objectFromDictionary:d], @"Import should not throw exception" );
    XCTAssertNotNil( johndoe, @"Failed to create object" );
    
    Address *johnsAddress = johndoe.address;
    XCTAssertNotNil( johnsAddress, @"Failed to import address using custom block" );
    if ( johnsAddress ) {
        XCTAssertEqualObjects( johnsAddress.street1, @"101 Main", @"Failed to import street1" );
        XCTAssertEqualObjects( johnsAddress.street2, @"Apt #2", @"Failed to import street2" );
        XCTAssertEqualObjects( johnsAddress.city, @"Boston", @"Failed to import city" );
        XCTAssertEqualObjects( johnsAddress.state, @"MA", @"Failed to import state" );
        XCTAssertEqualObjects( johnsAddress.zipCode, @"02111", @"Failed to import zip code" );
    }
}

- (void)test_existingObject
{
    // Make sure john is already in the data store
    XCTAssertNil( [[TestDataStore sharedInstance] objectWithClassName:@"Person" forId:@100], @"Test person should already be in data store" );
    
    NSDictionary *d = @{
        @"id" : @100,
        @"firstname" : @"Bob",
        @"lastname" : @"Dole"
    };

    
}

- (void)test_keyPermutations
{
    NSArray *keyPermutations = @[@"firstname", @"FirstName", @"first_name", @"First_Name"];
    
    for ( NSString *key in keyPermutations ) {
        NSDictionary *d = @{ key : key };
        XCTAssertNoThrow( [self.testPerson rzai_importValuesFromDict:d], @"Import should not throw exception" );
        XCTAssertEqualObjects( self.testPerson.firstName, key, @"Permutation failed: %@", key );
    }
}

- (void)test_setNil
{
    NSDictionary *d = @{ @"firstName" : [NSNull null] };
    XCTAssertNoThrow( [self.testPerson rzai_importValuesFromDict:d], @"Null value should not cause exception" );
    XCTAssertNil( self.testPerson.firstName, @"Failed to set firstname to nil" );
}

- (void)test_typeConversion
{
    // convert string to number
    NSDictionary *d = @{ @"id" : @"666" };
    XCTAssertNoThrow( [self.testPerson rzai_importValuesFromDict:d], @"Import should not throw exception" );
    XCTAssertEqualObjects( self.testPerson.ID, @666, @"Failed to convert string to number during import" );
    
    // convert number to string
    d = @{ @"firstname" : @666 };
    XCTAssertNoThrow( [self.testPerson rzai_importValuesFromDict:d], @"Import should not throw exception" );
    XCTAssertEqualObjects( self.testPerson.firstName, @"666", @"Failed to convert number to string during import" );
    
    // convert unix time to date
    NSDate *now = [NSDate date];
    NSTimeInterval t_epoch = [now timeIntervalSince1970];
    d = @{ @"lastupdated" : @(t_epoch) };
    XCTAssertNoThrow( [self.testPerson rzai_importValuesFromDict:d], @"Import should not throw exception" );
    XCTAssertEqual( [self.testPerson.lastUpdated timeIntervalSince1970], t_epoch, @"Failed to import date from unix time" );
}

- (void)test_dateConversion
{
    // Test standard ISO
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSDate *now = [NSDate date];
    
    NSString *dateString = [dateFormatter stringFromDate:now];
    XCTAssertNotNil( dateString, @"Failed to format date" );

    NSDictionary *d = @{ @"last_updated" : dateString };
    XCTAssertNoThrow( [self.testPerson rzai_importValuesFromDict:d], @"Null value should not cause exception" );
    
    NSString *resultDateString = [dateFormatter stringFromDate:self.testPerson.lastUpdated];
    XCTAssertEqualObjects( dateString, resultDateString, @"Failed to import date correctly" );
    
    // Test custom format
    dateFormatter.dateFormat = kAddressLastUpdatedFormat;
    
    Address *address = [Address new];
    dateString = [dateFormatter stringFromDate:now];
    d = @{ @"last_updated" : dateString };
    
    XCTAssertNoThrow( [address rzai_importValuesFromDict:d], @"Null value should not cause exception" );

    resultDateString = [dateFormatter stringFromDate:address.lastUpdated];
    XCTAssertEqualObjects( dateString, resultDateString, @"Failed to import date correctly" );
}

- (void)test_customMapping
{
    Address *address = [Address new];

    // Both custom and inferred mappings should work
    NSString* const theStreet = @"101 Main St.";
    NSDictionary *d = @{ @"street1" : theStreet };
    
    XCTAssertNoThrow( [address rzai_importValuesFromDict:d], @"Null value should not cause exception" );
    XCTAssertEqualObjects( address.street1, theStreet, @"Failed to import using inferred property mapping" );
    
    d = @{ @"street" : theStreet };
    XCTAssertNoThrow( [address rzai_importValuesFromDict:d], @"Null value should not cause exception" );
    XCTAssertEqualObjects( address.street1, theStreet, @"Failed to import using overridden property mapping" );
}

- (void)test_customImport
{
    
}

@end
