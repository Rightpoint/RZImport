//
//  ModelObject.swift
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

class ModelObject : NSObject, RZAutoImportable {
    
    let ID: UInt32?
    var lastUpdated: NSDate?
    
    init() {}
    
    init(identifier: UInt32) {
        self.ID = identifier
    }

}
