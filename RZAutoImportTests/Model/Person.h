//
//  Person.h
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/21/14.
//
//

#import "ModelObject.h"

@interface Person : ModelObject

@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;

@end
