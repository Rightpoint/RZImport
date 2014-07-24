//
//  Job.h
//  RZImportTests
//
//  Created by alex.rouse on 7/24/14.
//
//

#import "ModelObject.h"

@interface Job : ModelObject

@property (nonatomic, copy) NSString *companyName;
@property (nonatomic, copy) NSString *title;

@end
