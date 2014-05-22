RZAutoImport
============

Tired of writing boilerplate to import deserialized API responses to model objects? 

Tired of dealing with dozens and dozens of string keys? 

RZAutoImport is here to help!  

RZAutoImport is a category on `NSObject` and an accompanying optional protocol for creating and updating model objects in your iOS or OSX applications. It's particularly useful for importing objects from deserialized JSON HTTP responses in REST API's, but it works with any `NSDictionary` or array of dictionaries that you need to convert to native model objects.

#### Convenient

Property names are inferred from similarly named string keys in an `NSDictionary` and performs automatic type-conversion whenever possible. No need to reference string constants all over the place, just name your properties in a similar way to the keys in the dictionary and let RZAutoImport handle it for you.

RZAutoImport automatically performs case-insensitive matches between property names and key names, ignoring underscores. For example, all of the following keys will map to a property named `firstName`:

- `firstName`
- `FirstName`
- `first_name`
- `FiRst_NAme`


#### Flexible

Can't name your properties the same as the keys in the dictionary? Need to perform extra validation or import logic? No problem! The `RZAutoImportable` protocol has hooks for specifying custom mappings, custom import blocks per-key, and more!

#### Performant

Key/property mappings are created once and cached, so once an object type has been imported once, subsequent imports are super-speedy!

#### Example

```
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

## Documentation

For most in-depth and up-to-date documentation, please read the Apple-doc commented header files in the source code.

### Basic Usage

RZAutoImport can be used to create model objects from a either a dictionary or an array of dictionaries.

```
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

```
Person *myPerson = self.person;
[myPerson rzai_updateFromDictionary:someDictionary];
```

### Custom Mappings

If you need to provide a custom mapping from a dictionary key to a property name, implement the `RZAutoImportable` protocol on your model class. Custom mappings will take precedence over inferred mappings, but both can be used for the same class.

```
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


You can also provide a totally custom import block for specific validation or import logic, or nested relationships with other model objects. Custom blocks also take precedence over inferred mappings, but again, both can be used. If nil is returned, no block will be used to import the value for the given key.

```
- (RZAutoImportableCustomImportBlock)rzai_customImportBlockForKey:(NSString *)key value:(id)value
{
	if ( [key isEqualToString:@"address"] ) {
		return ^{
			
		};
	}
	return nil;
}

```

### Uniquing Objects

