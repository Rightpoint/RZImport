//
//  ModelObject.h
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/22/14.
//
//

#import <Foundation/Foundation.h>

@interface ModelObject : NSObject <RZAutoImportable>

@property (nonatomic, readonly, copy) NSNumber *ID;
@property (nonatomic, copy) NSDate   *lastUpdated;

- (instancetype)initWithID:(NSNumber *)theID;

@end
