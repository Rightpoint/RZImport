//
//  ModelObject.m
//  RZImport
//
//  Created by Nick Donaldson on 5/22/14.
//
//

#import "ModelObject.h"

@implementation ModelObject

- (instancetype)initWithID:(NSNumber *)theID
{
    self = [super init];
    if ( self ) {
        _ID = theID;
    }
    return self;
}

@end
