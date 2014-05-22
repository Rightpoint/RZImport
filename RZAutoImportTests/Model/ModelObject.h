//
//  ModelObject.h
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/22/14.
//
//

#import <Foundation/Foundation.h>

@interface ModelObject : NSObject <RZAutoImportable>

@property (nonatomic, copy) NSNumber *ID;
@property (nonatomic, copy) NSDate   *lastUpdated;

@end
