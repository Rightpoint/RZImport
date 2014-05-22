//
//  BigObject.m
//  RZAutoImport
//
//  Created by Nick Donaldson on 5/22/14.
//
//

#import "BigObject.h"

@implementation BigObject

- (BOOL)rzai_shouldImportValue:(id)value forKey:(NSString *)key
{
    // emulate a long (1 second) import for thread contention testing
    sleep(1);
    self.lotsOfData = [NSData data];
    return NO;
}

@end
