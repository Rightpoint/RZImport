//
//  Book.h
//  RZImportTests
//
//  Created by Bradley Smith on 12/9/15.
//
//

#import "ModelObject.h"

@interface Book : ModelObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *altTitle;

@end
