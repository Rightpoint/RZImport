//
//  Person.h
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/21/14.
//
//

#import <Foundation/Foundation.h>

@interface Person : NSObject <RZAutoImportable>

@property (nonatomic, copy) NSNumber *ID;
@property (nonatomic, copy) NSDate   *lastUpdated;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;

@end
