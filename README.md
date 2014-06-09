RZAutoImport
============

[![Build Status](https://travis-ci.org/Raizlabs/RZAutoImport.svg)](https://travis-ci.org/Raizlabs/RZAutoImport)

Tired of writing boilerplate to import deserialized API responses to model objects? 

Tired of dealing with dozens and dozens of string keys? 

RZAutoImport is here to help!  

RZAutoImport is a category on `NSObject` and an accompanying optional protocol for creating and updating model objects in your iOS applications. It's particularly useful for importing objects from deserialized JSON HTTP responses in REST API's, but it works with any `NSDictionary` or array of dictionaries that you need to convert to native model objects.

#### Convenient

Property names are inferred from similarly named string keys in an `NSDictionary` and performs automatic type-conversion whenever possible. No need to reference string constants all over the place, just name your properties in a similar way to the keys in the dictionary and let RZAutoImport handle it for you.

RZAutoImport automatically performs case-insensitive matches between property names and key names, ignoring underscores. For example, all of the following keys will map to a property named `firstName`:

- `firstName`
- `FirstName`
- `first_name`
- `FiRst_NAme`


#### Flexible

Can't name your properties the same as the keys in the dictionary? Need to perform extra validation or import logic? No problem! The `RZAutoImportable` protocol has hooks for specifying custom mappings, custom import logic and validation on a per-key basis, and more!

#### Performant

Key/property mappings are created once and cached, so once an object type has been imported once, subsequent imports are super-speedy!

#### Example

```obj-c
@interface Person : NSObject

@property (nonatomic, copy) NSNumber *ID;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;

@end

...

// Dictionary with some key/value pairs representing a person
NSDictionary *myDictionary = @{ 
	@"id" : @100,
	@"first_name" : @"Bob",
	@"last_name" : @"Smith"
};

// Create a new Person instance by automatically inferring key/property mappings
Person *newPerson = [Person rzai_objectFromDictionary:myDictionary];
NSLog(@"ID: %@ Name: %@ %@", newPerson.ID, newPerson.firstName, newPerson.lastName);
```

##### Console Output:

```
ID: 100 Name: Bob Smith
```
## Installation

#### CocoaPods

*TODO*

#### Manual Installation

Simply copy the files in the `RZAutoImport` directory into your project, add them to your target, and off you go!

**Note**: The `Private` directory contains private headers that are not intended for public usage.

## Documentation

For most in-depth and up-to-date documentation, please read the Apple-doc commented header files in the source code.

### Basic Usage

RZAutoImport can be used to create model objects from a either a dictionary or an array of dictionaries.

```obj-c
#import "NSObject+RZAutoImport.h"

...

- (void)fetchThePeople
{
	[self.apiClient get:@"/people" completion:^(NSData *responseData, NSError *error) {
		
		if ( !error ) {
		
			NSError *jsonErr = nil;
			id deserializedResponse = [NSJSONSerialization JSONObjectWithData:responseData
                                                                      options:kNilOptions
                                                                        error:&jsonErr];
			if ( !jsonErr ) {
			
				// convert to native objects
				if ( [deserializedResponse isKindOfClass:[NSDictionary class]] ) {
					Person *newPerson = [Person rzai_objectFromDictionary:deserializedResponse];
					// ... do something with the person ...
				}
				else if ( [deserializedResponse isKindOfClass:[NSArray class]] ) {
					NSArray *people = [Person rzai_objectsFromArray:deserializedResponse];
					// ... do something with the people ...
				}
			}
		}
	}];	
}

```

You can also update an existing object instance from a dictionary.

```obj-c
Person *myPerson = self.person;
[myPerson rzai_updateFromDictionary:someDictionary];
```

### Custom Mappings

If you need to provide a custom mapping from a dictionary key to a property name, implement the `RZAutoImportable` protocol on your model class. Custom mappings will take precedence over inferred mappings, but both can be used for the same class.

```obj-c
#import "RZAutoImportable.h"

@interface MyModelClass : NSObject <RZAutoImportable>

@property (nonatomic, copy) NSNumber *objectID;
@property (nonatomic, copy) NSString *zipCode;

@end


@implementation MyModelClass

+ (NSDictionary *)rzai_customKeyMappings
{
	// Map dictionary key "zip" to property "zipCode"
	// and dictionary key "id" to property "objectID"
	return @{
		@"zip" : @"zipCode",
		@"id" : @"objectID"
	};
}

@end

```

You can also prevent RZAutoImport from importing a value for a particular key, or import the value of a key using your own custom logic. 

```obj-c
- (BOOL)rzai_shouldImportValue:(id)value forKey:(NSString *)key;
{
	if ( [key isEqualToString:@"zip"] ) {
		// validation - must be a string that only contains numbers
		if ( [value isKindOfClass:[NSString class]] ) {
			return ([value rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location == NSNotFound);
		}
		return NO;
	}
	else if ( [key isEqualToString:@"address"] ) {
		if ( [value isKindOfClass:[NSDictionary class]] ) {
			// custom import logic
			self.address = [Address rzai_objectFromDictionary:value];
		}
		return NO;
	}
	return YES;
}

```

### Uniquing Objects

`RZAutoImportable` also has a handy method that you can implement on your classes to prevent duplicate objects from being created when using `rzai_objectFromDictionary:` or `rzai_objectsFromArray:`.

```obj-c
+ (id)rzai_existingObjectForDict:(NSDictionary *)dict
{
	// If there is already an object in the data store with the same ID, return it.
	// The existing instance will be updated and returned instead of a new instance.
    NSNumber *objID = [dict objectForKey:@"id"];
    if ( objID != nil ) {
        return [[DataStore sharedInstance] objectWithClassName:@"Person" forId:objID];
    }
    return nil;
}
```

## Known Issues

RZAutoImport uses the default designated initializer `init` when it creates new object instances, therefore it cannot be used out-of-the-box with classes that require another designated initializer. However, to get around this, you can override `+rzai_existingObjectForDict:` on any class to *always* return a new object created with the proper initializer (or an existing object).

For example, RZAutoImport cannot be used out-of-the-box to create valid instances of a subclass of `NSManagedObject`, since managed objects must be initialized with an entity description. However, there is no reason it will not work for updating existing instances of a subclass of `NSManagedObject` from a dictionary, or by overriding `+rzai_existingObjectForDict` to return a new object inserted into the correct managed object context.

## License

RZAutoImport is licensed under the MIT license. See the `LICENSE` file for details.
