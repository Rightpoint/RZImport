//
//  Person.h
//  RZImport
//
//  Created by Nick Donaldson on 5/21/14.
//
//

#import "ModelObject.h"

@class Address;
@class Job;

@interface Person : ModelObject

@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *colorPref;
@property (nonatomic, strong) Address *address;
@property (nonatomic, strong) Job *job;
@property (nonatomic, assign) bool deceased;

@end

@interface PersonCustomProps : Person
@end

