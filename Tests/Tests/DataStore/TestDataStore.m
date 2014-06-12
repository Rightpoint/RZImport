//
//  TestDataStore.m
//  RZImport
//
//  Created by Nick Donaldson on 5/22/14.
//
//

#import "TestDataStore.h"

@interface TestDataStore ()

@property (nonatomic, strong) NSMutableDictionary *objectCache;

@end

@implementation TestDataStore

+ (instancetype)sharedInstance
{
    static TestDataStore *s_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_sharedInstance = [[self alloc] init];
    });
    return s_sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        _objectCache = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Public

- (void)addObject:(ModelObject *)modelObject
{
    NSParameterAssert(modelObject);
    NSAssert(modelObject.ID != nil, @"Objects must have an ID to be inserted into the database");
    
    NSString *className = NSStringFromClass([modelObject class]);
    [[self objectCacheForClassName:className] setObject:modelObject forKey:modelObject.ID];
}

- (void)removeObject:(ModelObject *)modelObject
{
    NSParameterAssert(modelObject);
    NSAssert(modelObject.ID != nil, @"Objects must have an ID to be removed from the database");
    
    NSString *className = NSStringFromClass([modelObject class]);
    [[self objectCacheForClassName:className] removeObjectForKey:modelObject.ID];
}

- (id)objectWithClassName:(NSString *)className forId:(NSNumber *)objectID
{
    NSParameterAssert(className);
    NSParameterAssert(objectID);
    return [[self objectCacheForClassName:className] objectForKey:objectID];
}

#pragma mark - Private

- (NSMutableDictionary *)objectCacheForClassName:(NSString *)className
{
    NSMutableDictionary *objects = [self.objectCache objectForKey:className];
    if ( objects == nil ) {
        objects = [NSMutableDictionary dictionary];
        [self.objectCache setObject:objects forKey:className];
    }
    return objects;
}

@end
