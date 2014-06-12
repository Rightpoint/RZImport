//
//  BigObject.m
//  RZImport
//
//  Created by Nick Donaldson on 5/22/14.
//
//

#import "BigObject.h"

@implementation BigObject

+ (NSDictionary *)rzi_customMappings
{
    // test thread contention by having this take awhile
    sleep(1);
    return @{};
}

@end
