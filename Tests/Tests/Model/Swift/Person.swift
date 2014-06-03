//
//  Person.swift
//  RZAutoImportTests
//
//  Created by Nick Donaldson on 6/3/14.
//
//

#if os(OSX)
    import Cocoa
#else
    import UIKit
#endif

class Person: ModelObject {
    
    var firstName: String?
    var lastName: String?
    
}
