//
//  Person.h
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/21/14.
//
//

#import "ModelObject.h"

@class Address;

@interface Person : ModelObject

@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;

@property (nonatomic, strong) Address *address;

@end
