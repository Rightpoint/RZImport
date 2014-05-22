RZAutoImport
============

Tired of writing boilerplate to import deserialized API responses to model objects? Tired of dealing with dozens and dozens of string keys? `RZAutoImport` is here to help!  `RZAutoImport` is a category on `NSObject` and an accompanying optional protocol for creating and updating model objects in your iOS or OSX applications. `RZAutoImport` is **perfect** for importing objects from deserialized JSON HTTP responses in REST API's, but it works with any `NSDictionary` or `NSArray` of dictionaries.

#### Convenient

Property names are inferred from similarly named string keys in an `NSDictionary` and performs automatic type-conversion whenever possible. No need to reference string constants all over the place, just name your properties in a similar way to the keys in the dictionary and let `RZAutoImport` handle it for you.

`RZAutoImport` automatically performs case-insensitive matches between property names and key names, ignoring underscores. For example, all of the following keys will map to a property named `firstName`:

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


## Documentation

For most in-depth and up-to-date documentation, please read the Apple-doc commented header files in the source code.

### Basic Usage



### Custom Mappings

### Uniquing Objects

