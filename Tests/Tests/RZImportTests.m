//
//  RZImportTests.m
//  RZImportTests
//
//  Created by Nick Donaldson on 5/21/14.
//
//

#import <XCTest/XCTest.h>

#import "NSObject+RZImport.h"
#import "Person.h"
#import "BigObject.h"
#import "Address.h"
#import "Job.h"
#import "Book.h"
#import "TestDataStore.h"

extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));

@interface RZImportTests : XCTestCase

@property (nonatomic, strong) Person *testPerson;

@end

@implementation RZImportTests

#pragma mark - Setup

- (void)setUp
{
    [super setUp];
    
    Person *johndoe = [[Person alloc] initWithID:@100];
    johndoe.lastUpdated = [NSDate date];
    johndoe.firstName = @"John";
    johndoe.lastName = @"Doe";
    self.testPerson = johndoe;
    
    [[TestDataStore sharedInstance] addObject:self.testPerson];
}

- (void)tearDown
{
    [super tearDown];
    
    [[TestDataStore sharedInstance] removeObject:self.testPerson];
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
    XCTAssertNoThrow( johndoe = [Person rzi_objectFromDictionary:d], @"Import should not throw exception" );
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
    XCTAssertNoThrow( johndoe = [Person rzi_objectFromDictionary:d], @"Import should not throw exception" );
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
    XCTAssertNotNil( [[TestDataStore sharedInstance] objectWithClassName:@"Person" forId:@100], @"Test person should already be in data store" );
    
    NSDictionary *d = @{
        @"id" : @100,
        @"firstname" : @"Bob",
        @"lastname" : @"Dole"
    };

    Person *samePerson = [Person rzi_objectFromDictionary:d];
    XCTAssertEqual( samePerson, self.testPerson, @"Should be same object from data store" );
    XCTAssertEqualObjects( self.testPerson.firstName, @"Bob", @"Failed to set new first name" );
    XCTAssertEqualObjects( self.testPerson.lastName, @"Dole", @"Failed to set new last name" );
}

- (void)test_keyPermutations
{
    NSArray *keyPermutations = @[@"firstname", @"FirstName", @"first_name", @"First_Name"];
    
    for ( NSString *key in keyPermutations ) {
        NSDictionary *d = @{ key : key };
        XCTAssertNoThrow( [self.testPerson rzi_importValuesFromDict:d], @"Import should not throw exception" );
        XCTAssertEqualObjects( self.testPerson.firstName, key, @"Permutation failed: %@", key );
    }
}

- (void)test_setNil
{
    NSDictionary *d = @{ @"firstName" : [NSNull null] };
    XCTAssertNoThrow( [self.testPerson rzi_importValuesFromDict:d], @"Null value should not cause exception" );
    XCTAssertNil( self.testPerson.firstName, @"Failed to set firstname to nil" );
}

- (void)test_typeConversion
{
    // convert string to number
    NSDictionary *d = @{ @"id" : @"666" };
    XCTAssertNoThrow( [self.testPerson rzi_importValuesFromDict:d], @"Import should not throw exception" );
    XCTAssertEqualObjects( self.testPerson.ID, @666, @"Failed to convert string to number during import" );
    
    // convert number to string
    d = @{ @"firstname" : @666 };
    XCTAssertNoThrow( [self.testPerson rzi_importValuesFromDict:d], @"Import should not throw exception" );
    XCTAssertEqualObjects( self.testPerson.firstName, @"666", @"Failed to convert number to string during import" );
    
    // convert unix time to date
    NSDate *now = [NSDate date];
    NSTimeInterval t_epoch = [now timeIntervalSince1970];
    d = @{ @"lastupdated" : @(t_epoch) };
    XCTAssertNoThrow( [self.testPerson rzi_importValuesFromDict:d], @"Import should not throw exception" );
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
    XCTAssertNoThrow( [self.testPerson rzi_importValuesFromDict:d], @"Import should not throw exception"  );
    
    NSString *resultDateString = [dateFormatter stringFromDate:self.testPerson.lastUpdated];
    XCTAssertEqualObjects( dateString, resultDateString, @"Failed to import date correctly" );
    
    // Test custom format
    dateFormatter.dateFormat = kAddressLastUpdatedFormat;
    
    Address *address = [Address new];
    dateString = [dateFormatter stringFromDate:now];
    d = @{ @"last_updated" : dateString };
    
    XCTAssertNoThrow( [address rzi_importValuesFromDict:d], @"Import should not cause exception"  );

    resultDateString = [dateFormatter stringFromDate:address.lastUpdated];
    XCTAssertEqualObjects( dateString, resultDateString, @"Failed to import date correctly" );
}

- (void)test_customMapping
{
    Address *address = [Address new];

    // Both custom and inferred mappings should work
    NSString* const theStreet = @"101 Main St.";
    NSDictionary *d = @{ @"street1" : theStreet };
    
    XCTAssertNoThrow( [address rzi_importValuesFromDict:d], @"Import should not throw exception" );
    XCTAssertEqualObjects( address.street1, theStreet, @"Failed to import using inferred property mapping" );
    
    d = @{ @"street" : theStreet };
    XCTAssertNoThrow( [address rzi_importValuesFromDict:d], @"Import should not throw exception"  );
    XCTAssertEqualObjects( address.street1, theStreet, @"Failed to import using overridden property mapping" );
}

- (void)test_extraInlineMapping
{
    Address *address = [Address new];
    
    // Both custom and inferred mappings should work
    NSString* const theStreet = @"101 Main St.";
    NSDictionary *d = @{ @"street_where_I_live" : theStreet };
    
    XCTAssertNoThrow( [address rzi_importValuesFromDict:d withMappings:@{ @"street_where_I_live" : @"street1" }], @"Import should not throw exception" );
    XCTAssertEqualObjects( address.street1, theStreet, @"Failed to import using extra inline property mapping" );
}

- (void)test_keypathMapping
{
    Person *person = [Person new];
    
    NSDictionary *d = @{
        @"id" : @555,
        @"profile" : @{
            @"extraneous" : @"information",
            @"first_name" : @"Bob",
            @"last_name" : @"Smith",
            @"prefs" : @{
                @"color" : @"Gray"
            }
        }
    };
    
    XCTAssertNoThrow( [person rzi_importValuesFromDict:d], @"Import should not throw exception" );
    XCTAssertEqualObjects( person.firstName, @"Bob", @"First name failed to import from keypath" );
    XCTAssertEqualObjects( person.lastName, @"Smith", @"Last name failed to import from keypath" );
    XCTAssertEqualObjects( person.colorPref, @"Gray", @"Color pref failed to import from three-component keypath" );
}


- (void)test_validation
{
    Address *address = [Address new];
    
    NSString* const theStreet = @"101 Main St.";
    NSString* const theZip = @"01234";
    NSDictionary *d = @{
        @"street1" : theStreet,
        @"zip" : theZip
    };
    
    XCTAssertNoThrow( [address rzi_importValuesFromDict:d], @"Import should not throw exception" );
    XCTAssertEqualObjects( address.street1, theStreet, @"Failed to import using inferred property mapping" );
    
    // Ensure that the valid zip code imported correctly
    XCTAssertEqualObjects( address.zipCode, theZip, @"Failed to import valid zip code");
    
    // Import invalid zip code and make sure it fails - should keep previous value
    d = @{ @"zip" : @"not10202valid" };
    
    XCTAssertNoThrow( [address rzi_importValuesFromDict:d], @"Import should not throw exception" );
    XCTAssertEqualObjects( address.zipCode, theZip, @"Failed block import of invalid zip code");
}

- (void)test_threadSafety
{
    //
    // Thread safety test
    //
    // Force thread contention by having a long (1 second) background import in progress
    // while a main thread import starts, 0.5 seconds into the background import.
    //
    // The recursive lock should prevent any resource contention during an import.
    //
    
    for ( NSUInteger i = 0; i < 5; i ++ ) {
        
        NSLog(@"Testing thread contention - iteration %lu", (unsigned long)(i + 1));
        
       __block BOOL done = NO;
        
        NSDictionary *d = @{ @"id" : @100 };
        
        dispatch_queue_t bg1 = dispatch_queue_create("com.rzai.bg1", DISPATCH_QUEUE_SERIAL);
        
        __block BOOL delayFired = NO;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            BigObject *big1 = nil;
            XCTAssertNoThrow( big1 = [BigObject rzi_objectFromDictionary:d], @"Should not cause exception with thread contention");
            XCTAssertNotNil(big1, @"There should be an object");
            delayFired = YES;
        });
        
        dispatch_async(bg1, ^{
            XCTAssertFalse(delayFired, @"Delayed dispatch should not have fired yet");
            BigObject *big2 = nil;
            XCTAssertNoThrow( big2 = [BigObject rzi_objectFromDictionary:d], @"Should not cause exception with thread contention");
            XCTAssertNotNil(big2, @"There should be an object");
        });
        
        while ( !done && !delayFired ) {
            [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] dateByAddingTimeInterval:0.1]];
        }
    }
}

- (void)test_ignoreKeys
{
    Address *address = [Address new];
    
    NSString* const theStreet = @"101 Main St.";
    NSString* const theZip = @"01234";
    NSDictionary *d = @{
        @"street1" : theStreet,
        @"zip" : theZip,
        @"ignoreMe" : @"Don't import this"
    };
    
    XCTAssertNil( address.ignoreMe, @"Property should be nil initially" );
    XCTAssertNoThrow( [address rzi_importValuesFromDict:d], @"Import should not throw exception" );
    XCTAssertEqualObjects( address.street1, theStreet, @"Failed to import using inferred property mapping" );
    XCTAssertEqualObjects( address.zipCode, theZip, @"Failed to import valid zip code");
    XCTAssertNil( address.ignoreMe, @"Property still be nil" );

}

- (void)test_unknownKeyWarningCache
{
    /*
     *  This test is for visual verification of the log.
     *  Only one warning should be logged for each unknown key ("favoriteFood" and "zodiac").
     */
    
    NSMutableArray *peopleDicts = [NSMutableArray array];
    [peopleDicts addObject:@{ @"id" : @1000, @"favoriteFood" : @"Steak", @"zodiac" : @"Capricorn" }];
    [peopleDicts addObject:@{ @"id" : @1001, @"favoriteFood" : @"Tacos", @"zodiac" : @"Gemini" }];
    [peopleDicts addObject:@{ @"id" : @1002, @"favoriteFood" : @"Biryani", @"zodiac" : @"Pisces" }];
    
    NSArray *newPeeps = [Person rzi_objectsFromArray:peopleDicts];
    XCTAssertEqual(newPeeps.count, (NSUInteger)3, @"Wrong number of people");
}

- (void)test_nestedImport
{
    NSError      *err = nil;
    NSDictionary *d   = [self loadTestJson:@"test_person_job" error:&err];
    
    XCTAssertNil( err, @"Error reading json: %@", err );
    XCTAssertNotNil( d, @"Could not deserialize json" );
    
    Person *johndoe = nil;
    XCTAssertNoThrow( johndoe = [Person rzi_objectFromDictionary:d], @"Import should not throw exception" );
    XCTAssertNotNil( johndoe, @"Failed to create object" );
    
    Job *johnsJob = johndoe.job;
    XCTAssertNotNil( johnsJob, @"Failed to import job Automatically" );
    if ( johnsJob ) {
        XCTAssertEqualObjects( johnsJob.title, @"Software Engineer", @"Failed to import job title" );
        XCTAssertEqualObjects( johnsJob.companyName, @"Raizlabs", @"Failed to import job companyName" );
    }
}

- (void)test_nestedImportCustomKey
{
    NSString* const companyName = @"Raizlabs";
    NSString* const title = @"Designer";
    NSDictionary *d = @{
                        @"id" : @1234,
                        @"employment" : @{
                                @"companyName" : companyName,
                                @"title" : title
                                }
                        };
    Person *guy = [Person rzi_objectFromDictionary:d];
    XCTAssertNotNil(guy, @"Person should not be nil");
    
    Job *guysJob = guy.job;
    XCTAssertNotNil(guysJob, @"Guy should have a job");
    XCTAssertEqualObjects(guysJob.companyName, companyName, @"Failed to import Company Name");
    XCTAssertEqualObjects(guysJob.title, title, @"Failed to import title");
}

- (void)test_shouldWillDidImportValues {
    NSError *error = nil;
    NSArray *array = [self loadTestJson:@"test_books" error:&error];

    XCTAssertNil(error, @"Error reading json: %@", error);
    XCTAssertNotNil(array, @"Could not deserialize json");

    NSArray *books = [Book rzi_objectsFromArray:array];

    XCTAssertNotNil(books, @"Failed to import any books");
    XCTAssertEqual(books.count, 3, @"Failed to import correct number of books");

    for (Book *book in books) {
        XCTAssertEqualObjects(book.title, book.subtitle);
        XCTAssertEqualObjects(book.title, book.altTitle);
    }
}

@end
