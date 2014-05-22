//
//  TestDataStore.h
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/22/14.
//
//

#import "ModelObject.h"

@interface TestDataStore : NSObject

+ (instancetype)sharedInstance;

- (void)addObject:(ModelObject *)modelObject;
- (id)objectWithClassName:(NSString *)className forId:(NSNumber *)objectID;

@end
