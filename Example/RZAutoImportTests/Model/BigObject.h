//
//  BigObject.h
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/22/14.
//
//

#import <Foundation/Foundation.h>
#import "ModelObject.h"

/**
 *  Sleeps thread during import to simulate a long import for concurrency testing.
 */
@interface BigObject : ModelObject

@property (nonatomic, copy) NSData *lotsOfData;

@end
