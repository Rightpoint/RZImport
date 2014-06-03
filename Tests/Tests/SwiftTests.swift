//
//  SwiftTests.swift
//  RZAutoImportTests
//
//  Created by Nick Donaldson on 6/3/14.
//
//

import XCTest

class SwiftTests: XCTestCase {

    var testPerson: Person!
    
    override func setUp() {
        super.setUp()
        
        self.testPerson = Person()
        self.testPerson.firstName = "John"
        self.testPerson.lastName = "Doe"
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func loadTestJSON(fileName: String) -> AnyObject? {
        var url = NSBundle(forClass: self.dynamicType).URLForResource(fileName, withExtension: "json")
        if let data = NSData(contentsOfURL: url) as NSData? {
            return NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil)
        }

        return nil
    }
    
//
//  TESTS
//

    func test_ImportSwiftPerson() {
        if let test :NSDictionary? = self.loadTestJSON("test_person") as? NSDictionary? {
            var person :Person = Person.rzai_objectFromDictionary(test)
            XCTAssertNotNil( person, "Failed to create object" );
//            XCTAssert( person.lastUpdated is NSDate, "Failed to import last updated" ); // accuracy of date import verified in another test
            XCTAssertEqual( person.ID!, 12345, "Failed to import ID" );
            XCTAssertEqualObjects( person.firstName, "John", "Failed to import first name" );
            XCTAssertEqualObjects( person.lastName, "Doe", "Failed to import last name" );
        }
        else {
            XCTFail("Could not load JSON")
        }
    }

}
