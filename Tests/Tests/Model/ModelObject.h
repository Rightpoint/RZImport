//
//  ModelObject.h
//  RZImport
//
//  Created by Nick Donaldson on 5/22/14.
//
//

#import "NSObject+RZImport.h"

@interface ModelObject : NSObject <RZImportable>

@property (nonatomic, readonly, copy) NSNumber *ID;
@property (nonatomic, copy) NSDate   *lastUpdated;

- (instancetype)initWithID:(NSNumber *)theID;

@end
