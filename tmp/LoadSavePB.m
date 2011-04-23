/*
Copyright (C) 2008 Darrell Walisser walisser@mac.com

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

#import "LoadSavePB.h"
#import "Utilities.h"
//#import "MyNSObject.h"

#import <fcntl.h> // for open(), close(), write()
#import <unistd.h>

///
// static variables to store boolean constants
// this way it is easy to test for equality
// This is perhaps not necessary if strings are pooled.
///
static NSString* NSStringTrue  = @"TRUE";
static NSString* NSStringFalse = @"FALSE";

///
// "private" methods that I don't want anyone to use,
// so hide them in the implementation. private methods
// don't actually exist in ObjC
///
@interface LoadSavePB (PrivateMethods)

// recursive methods for linking & flattening the property list data
- (void) linkArray:(NSMutableArray*)root withObjects:(NSMutableDictionary*)objects;
- (void) linkDictionary:(NSMutableDictionary*)root withObjects:(NSMutableDictionary*)objects;

- (void) flattenArray:(NSMutableArray*) root 
            withCache:(NSMutableDictionary*) objectCache
          withObjects:(NSMutableDictionary*) objects;
- (void) flattenDictionary:(NSMutableDictionary*) root
                 withCache:(NSMutableDictionary*) objectCache
               withObjects:(NSMutableDictionary*) objects;

// object "serializing" method for flattening
- (NSString*) uuidStringForObject:(id)object
                          withCache:(NSMutableDictionary*)objectCache
                        withObjects:(NSMutableDictionary*)objects;

// methods for handling object description dictionaries ( used by above methods )
- (NSMutableDictionary*) addClassDescriptionForObject:(NSMutableDictionary*)object;
- (NSMutableDictionary*) getClassDescriptionForObject:(NSMutableDictionary*)object;

- (BOOL) knowLinkedStateOfField:(NSString*)field
                        ofClass:(NSString*)class;
                        
- (void) setFieldIsLinkedForField:(NSString*)field
                          ofClass:(NSString*)class
                          toValue:(BOOL)value;

- (BOOL) getFieldIsLinkedForField:(NSString*)field
                          ofClass:(NSString*)class;

// convenience methods, since we store booleans as strings in the tree
- (NSString*) boolToString:(BOOL)value;
- (BOOL) stringToBool:(NSString*)string;

@end

@implementation LoadSavePB


- (id) init
{
    // blow up here since you shouldn't use this initializer
    ASSERT ("Please use initWithFile!" == 0);
    
    return nil;
}

- (id) initWithFile:(NSString*)path
{
    NSDictionary	*readOnlyPlist;
    
    self = [ super init ];
    ASSERT (self != nil);
    
    // set instance variables
    wasLink = NO;
    
    // load the plist xml data
    //NSLog (@"-[ LoadSavePB initWithFile ] file=%@", path);
    readOnlyPlist = [ [ NSMutableDictionary alloc ] initWithContentsOfFile:path ];
    ASSERT (readOnlyPlist != nil);
    
    plist = [ [ Utilities mutablePlistDeepCopyDictionary:readOnlyPlist ] retain ];
    ASSERT (plist != nil);
    [ readOnlyPlist autorelease ];
    
    classDescDict = [ [ NSMutableDictionary alloc ] init ];
    ASSERT (classDescDict != nil);

    objectRoot = [ [ NSMutableArray alloc ] init ];
    ASSERT (objectRoot != nil);
    
    linkStack  = [ [ NSMutableArray alloc ] init ];
    // done setting instance variables
    
    return self;
}

- (void) dealloc
{
    [ linkStack autorelease ];
    [ objectRoot autorelease ];
    [ classDescDict autorelease ];
    [ plist autorelease ];
    [ super dealloc ];
}

- (NSMutableDictionary*) loadCatalogFile:(NSString*)path
{
    NSDictionary*			readOnlyPlist;
    NSMutableDictionary*	tmpPlist;    
    NSMutableDictionary*	objects;
    NSMutableDictionary* 	root;
    NSString* 	    		rootKey;
        
    // load the property list into a dictionary
    readOnlyPlist = [ [ NSMutableDictionary alloc ] initWithContentsOfFile:path ];
    ASSERT (readOnlyPlist != nil);
    tmpPlist = [ Utilities mutablePlistDeepCopyDictionary:readOnlyPlist ];
    ASSERT (tmpPlist != nil);
    [ readOnlyPlist autorelease ];
    
    // get the dictionary of serialized objects
    objects = [ tmpPlist objectForKey:@"objects" ];
    ASSERT (objects != nil);

    // get the key to the root object
    rootKey = [ tmpPlist objectForKey:@"rootObject" ];
    ASSERT (rootKey != nil);
    
    // get the root object
    root = [ objects objectForKey:rootKey ];
    ASSERT (root != nil);
    
    // link objects together, producing the complete plist graph
    [ self linkDictionary:root withObjects:objects ];

    // add linked dictionary to object root
    [ objectRoot addObject:root ];
    
    return root;
}

- (NSArray*) objectRoot
{
    return objectRoot;
}

- (void) linkArray:(NSMutableArray*)root
       withObjects:(NSMutableDictionary*)objects
{
    int 		numObjects;
    int			i;
    
    [ linkStack addObject:root ];
    
    numObjects = [ root count ];
    if (numObjects > 0) {
        
        for (i = 0; i < numObjects; i++) {
        
            id   	   value;
            
            value = [ root objectAtIndex:i ];
            ASSERT (value != nil);
            
            if ([ value isKindOfClass:[ NSString class ] ]) {
            
                // check if StringRef is a UUID
                NSMutableDictionary* object;
                
                // assume it is no coincidence that the string is a key for another dictionary
                object = [ objects objectForKey:value ];
                if (object != nil) {
                        
                        // make sure it is indeed a dictionary
                        ASSERT ([ object isKindOfClass:[ NSMutableDictionary class ] ]);
                        
                        if (![ linkStack containsObject:object ])
                            // make sure to link whatever was relocated, if necessary
                            [ self linkDictionary:object withObjects:objects ];
                        
                        // make the link now
                        [ root replaceObjectAtIndex:i withObject:object ];
                }
                
            }
            else
            if ([ value isKindOfClass:[ NSMutableDictionary class ] ]) {
                
                if (![ linkStack containsObject:value ])
                    [ self linkDictionary:value withObjects:objects ];
            }
            else
            if ([ value isKindOfClass:[ NSMutableArray class ] ]) {
            
                if (![ linkStack containsObject:value ])
                    [ self linkArray:value withObjects:objects ];
            }
            else {
            
                NSLog (@"unknown object class: %@", value);
                ASSERT ("unknown object class" == 0);
            }
        }
    }
    
    [ linkStack removeLastObject ];
}

-(void) linkDictionary:(NSMutableDictionary*)root withObjects:(NSMutableDictionary*)objects
{
    NSString*					className;
    NSArray*				    keys;
    int 						numKeys;
    int							i;

    [ linkStack addObject:root ];
    
    keys = [ root allKeys ];
    numKeys = [ keys count ];
    if (numKeys > 0)
    {
        // get the class name of the root object
        // the class name could be nil, 
        // in that case this isn't really an "object"
        // but a regular NSMutableDictionary
        className = [ root objectForKey:@"isa" ];
        
        // create the class description for this object
        if (className != nil) {
            [ self addClassDescriptionForObject:root ];
        }
        
        for (i = 0; i < numKeys; i++) {
        
            NSString* 	key;
            id		   	value;
            
            key = [ keys objectAtIndex:i ];
            value = [ root objectForKey:key ];
            ASSERT (value != nil);
            
            if ([ value isKindOfClass:[ NSString class ] ]) {
            
                // check if StringRef is a UUID
                NSMutableDictionary* object;
                
                // go ahead and try to assume that "value" indexes an object
                object = [ objects objectForKey:value ];
                if (object != nil) {
                        
                        // make sure the object was indeed a dictionary
                        ASSERT ([ object isKindOfClass:[ NSMutableDictionary class ] ]);
                        
                        if (![ linkStack containsObject:object ])
                            // make sure to link whatever was relocated if necessary
                            [ self linkDictionary:(NSMutableDictionary*)object withObjects:objects ];
                        
                        // tell the current object's description that this field is linked
                        if (className != nil) {
                            [ self setFieldIsLinkedForField:key ofClass:className toValue:YES ];
                        }
    
                        // do the actual link
                        [ root setObject:object forKey:key ];
                }
                
            }
            else {
            
                // tell the current object's description this is not a linked field
                if (className != nil) {
                    if ( [ self knowLinkedStateOfField:key ofClass:className ] ) {
                    
                        // this object has been visited already, 
                        // so don't change its linked state
                    }
                    else {
                    
                        [ self setFieldIsLinkedForField:key ofClass:className toValue:NO ];
                    }
                }
                
                if ([ value isKindOfClass:[ NSMutableDictionary class ] ]) {
    
                    if (![ linkStack containsObject:value ])
                        [ self linkDictionary:value withObjects:objects ];
                }
                else
                if ([ value isKindOfClass:[ NSMutableArray class ] ]) {
                    
                    if (![ linkStack containsObject:value ])
                        [ self linkArray:value withObjects:objects ];
                }
                else {
                
                    NSLog (@"unknown object class: %@", value);
                    ASSERT ("unknown object class" == 0);
                }
            }
        }
        //[ keys release ];
    }
    
    [ linkStack removeLastObject ];
}

- (void) link
{
    NSMutableDictionary*	objects;
    NSMutableDictionary*  	root;
    NSString*        		rootKey;
    
    // get the dictionary of serialized objects
    objects = [ plist objectForKey:@"objects" ];
    ASSERT (objects != nil);

    // get the key to the root object
    rootKey = [ plist objectForKey:@"rootObject" ];
    ASSERT (rootKey != nil);
    
    // get the root object
    root = [ objects objectForKey:rootKey ];
    ASSERT (root != nil);
    
    // link objects together, producing the complete plist graph
    [ self linkDictionary:root withObjects:objects ];

    // add the linked object to the graph
    [ plist setObject:root forKey:@"linkedRootObject" ];
    
    // debug code, to check up on linking process
    //CFDictionaryRemoveValue (plist, CFSTR("objects"));
    //CFDictionaryRemoveValue (plist, CFSTR("rootObject"));
    
    // add object to objectRoot
    [ objectRoot addObject:root ];
    
    wasLink = YES;
    wasFlatten = NO;
}

///
// This method keeps a cache of unique objects,
// and creates/returns a unique string that
// identifies the object
///
- (NSString*) uuidStringForObject:(id)object
                        withCache:(NSMutableDictionary*)objectCache
                      withObjects:(NSMutableDictionary*)objects
{
    NSString* objectKey;
    NSString* objectID;
    
    objectKey = [ NSString stringWithFormat:@"%d", (unsigned)object, nil ];
    objectID = [ objectCache objectForKey:objectKey ];
    if (objectID != nil) {

        return objectID;
    }
    else {
    
        char uuidCStr[25];
        
		// use the memory location of the object as a unique identifier
        // handle 2^30 different objects (assuming address is 4-byte aligned)
        sprintf (uuidCStr, "00000000" "00000000" "%.8X", (unsigned)object);
        
        objectID = [ [ NSString alloc ] initWithCString:uuidCStr ];
        ASSERT (objectID != nil);
        
        // add the object to the cache
        [ objectCache setObject:objectID forKey:objectKey ];
        [ objects setObject:object forKey:objectID ];
        
        // OK to autorelease here since Add above bumped refcount to 2
        [ objectID autorelease ];
        
        //[ objectKey autorelease ];
        return objectID;
    }
}


- (void) flattenArray:(NSMutableArray*) root 
            withCache:(NSMutableDictionary*) objectCache
          withObjects:(NSMutableDictionary*) objects
{                               
    int		numObjects;
    int		i;
    
    numObjects = [ root count ];
    if (numObjects == 0)
        return;
    
    ASSERT (numObjects > 0);
    
    [ linkStack addObject:root ];
                
    for (i = 0; i < numObjects; i++) {
    
        id   	value;
        
        value = [ root objectAtIndex:i ];
        ASSERT (value != nil);
        
        if ([ value isKindOfClass:[ NSMutableDictionary class ] ]) {
        
            if (![ linkStack containsObject:value ])
                [ self flattenDictionary:value withCache:objectCache withObjects:objects ];
            
            // presume (perhaps incorrectly) that all dictionaries in arrays are linked
            {
                NSString*	uuid;
                
                uuid = [ self uuidStringForObject:value withCache:objectCache withObjects:objects ];
                ASSERT (uuid != nil);
            
                [ root replaceObjectAtIndex:i withObject:uuid ];
            }
        }
        else
        if ([ value isKindOfClass: [ NSMutableArray class ] ]) {
        
            if (![ linkStack containsObject:value ])
                [ self flattenArray:value withCache:objectCache withObjects:objects ];
        }
        else if (! [ value isKindOfClass: [ NSString class ] ]) {
            
            NSLog (@"unknown object class: %@", value);
            ASSERT ("unknown object class" == 0);
        }
    
    }
    
    [ linkStack removeLastObject ];
}

- (void) flattenDictionary:(NSMutableDictionary*)	root
                 withCache:(NSMutableDictionary*)	objectCache
               withObjects:(NSMutableDictionary*)	objects
{                               
    NSString*		 className;
    NSArray*		 keys;
    int 			 numKeys;
    int				 i;
    
    keys = [ root allKeys ];
    numKeys = [ root count ];
    if (numKeys == 0)
        return;
    ASSERT (numKeys > 0);
    
    [ linkStack addObject:root ];
    
    // get the class name of the root object
    className = [ root objectForKey:@"isa" ];
    
    for (i = 0; i < numKeys; i++) {
    
        NSString* 	key;
        id   	value;
        
        key = [ keys objectAtIndex:i ];
        value = [ root objectForKey:key ];
        ASSERT (value != nil);
        
        if ([ value isKindOfClass:[ NSMutableDictionary class ] ]) {
            
            if (![ linkStack containsObject:value ])
                [ self flattenDictionary:value withCache:objectCache withObjects:objects ];
 
            if ( className != nil &&
                [ self getFieldIsLinkedForField:key ofClass:className ] ) {
                        
                NSString*	uuid;
                
                uuid = [ self uuidStringForObject:value withCache:objectCache withObjects:objects ];
                ASSERT (uuid != nil);
                
                [ root setObject:uuid forKey:key ];
            }
            else if (className != nil) {
                //printf ("hum, not a linked dictionary...");
                //CFShow(className);
                //printf("\n");
            }
        }
        else
        if ([ value isKindOfClass: [ NSMutableArray class ] ]) {
        
            if (![ linkStack containsObject:value ])
                [ self flattenArray:value withCache:objectCache withObjects:objects ];
        }
        else if (! [ value isKindOfClass: [ NSString class ] ]) {
        
            NSLog (@"unknown object class: %@", value);
            ASSERT ("unknown object class" == 0);
        }        
    }
    
    [ linkStack removeLastObject ];
}


- (void) flatten
{
    NSMutableDictionary*    objects;
    NSString*        		rootUUID;
    NSMutableDictionary*    root;
    NSMutableDictionary*	objectCache;
    
    // flatten undoes link: we must be linked before we can flatten
    ASSERT (wasLink);
    
    // first remove all of the old objects, they will be recreated in flattening
    objects = [ plist objectForKey:@"objects" ];
    ASSERT (objects != nil);
    [ objects removeAllObjects ];
    [ plist removeObjectForKey:@"rootObject" ];
    
    // start at the previously linked object
    root = [ plist objectForKey:@"linkedRootObject" ];
    ASSERT (root != nil);
    [ root retain ]; // want to keep the root around when linkedRoot is removed
    [ plist removeObjectForKey:@"linkedRootObject" ];

    objectCache = [ [ NSMutableDictionary alloc ] init ];
    
    rootUUID = [ self uuidStringForObject:root withCache:objectCache withObjects:objects ];
    [ plist setObject:rootUUID forKey:@"rootObject" ];
    //NSLog ("root UUID is %@", rootUUID);
    
    [ self flattenDictionary:root withCache:objectCache withObjects:objects ];
    
    wasLink = NO;
    wasFlatten = YES;
    
    // dump the object cache since it's no longer needed
    [ objectCache autorelease ];
}

- (void) dumpToFile:(NSString*)path
{
    ASSERT (YES == [ plist writeToFile:(NSString *)path atomically:YES ] );
}

- (NSMutableDictionary*) getLinkedGraph
{
    NSMutableDictionary*		root;
    
    if ( !wasLink ) {
        
        ASSERT (!wasFlatten && 
                "What is the point in relinking a flattened graph?");
        [ self link ];
    }
    
    root = [ plist objectForKey:@"linkedRootObject" ];
    ASSERT (root != nil);
    
    return root;
}

- (NSMutableDictionary*) createObjectWithClassName:(NSString*)className
{
    NSMutableDictionary*		classDesc;
    NSMutableDictionary*		exampleObject;
    NSMutableDictionary*		copyObject;
    
    //CFShow(classDescDict);
    classDesc = [ classDescDict objectForKey:className ];
    
    //CFShow(className);
    if (classDesc == nil)
	{
        NSLog(@"-[LoadSavePB createObjectWithClassName:] don't know about class \"%@\", dumping available classes\n",
              className);
		NSLog(@"%@", [ classDescDict allKeys ]);
	}           
    ASSERT (classDesc != nil);
    
    exampleObject = [ classDesc objectForKey:@"example" ];
    
    // note: I probably need to write deep copy here - yup
    
    copyObject = [ Utilities mutablePlistDeepCopyDictionary:exampleObject ];
    //copyObject = [ [ NSMutableDictionary alloc ]
    //    initWithDictionary:exampleObject copyItems:YES ];
    
        /*    
    copyObject = CFPropertyListCreateDeepCopy (
        kCFAllocatorDefault,
        exampleObject,
        kCFPropertyListMutableContainers
    );
*/

    ASSERT (copyObject != nil);
    ASSERT (copyObject != exampleObject);

    return copyObject;
}

- (NSMutableDictionary*) addClassDescriptionForObject:(NSMutableDictionary*)object
{
    NSMutableDictionary*		classDesc;
    NSMutableDictionary*		fields;
    NSString*					class;
    
    class = [ object objectForKey:@"isa" ];
    
    // check if we already have a description of the class
    classDesc = [ classDescDict objectForKey:class ];
    if (classDesc == nil) {
        
        // if not, create one
        fields = [ [ NSMutableDictionary alloc ] init ];
        ASSERT (fields != nil);
        
        classDesc = [ [ NSMutableDictionary alloc ] init ];
        ASSERT (classDesc != nil);
        
        [ classDesc setObject:fields forKey:@"fields" ];
        [ classDesc setObject:object forKey:@"example" ];
        [ classDescDict setObject:classDesc forKey:class ];
    }

    return classDesc;
}


- (NSMutableDictionary*) getClassDescriptionForObject:(NSMutableDictionary*)object
{
    return [ self addClassDescriptionForObject:object ];
}

- (BOOL) knowLinkedStateOfField:(NSString*)field
                        ofClass:(NSString*)class
{
    NSMutableDictionary*		classDesc;
    NSMutableDictionary*		fields;
    
    classDesc = [ classDescDict objectForKey: class ];
    ASSERT (classDesc != nil);
    
    fields = [ classDesc objectForKey:@"fields" ];
    ASSERT (fields != nil);
    
    return [ fields objectForKey:field ] != nil;
}

- (void) setFieldIsLinkedForField:(NSString*)field
                          ofClass:(NSString*)class
                          toValue:(BOOL)value
{
    NSMutableDictionary*		classDesc;
    NSMutableDictionary*		fields;    
    
    classDesc = [ classDescDict objectForKey: class ];
    ASSERT (classDesc != nil);
    
    fields = [ classDesc objectForKey:@"fields" ];
    ASSERT (fields != nil);
    
    // remove any previous value, since we can't overwrite it directly
    //[ fields removeObjectForKey:field ];
    
    // store the value as a string
    [ fields setObject:[ self boolToString:value ] forKey:field ];
    
    /*
    if (CFStringCompare (field, CFSTR("productReference"), 0) == kCFCompareEqualTo) {
    
        CFShow (class);
        CFShow (field);
        CFShow ([ self boolToString:value ]);
        
        if (value == NO) {
        
            char *ptr = nil;
            *ptr = 100;
        }
    }
    */
}

- (BOOL) getFieldIsLinkedForField:(NSString*)field
                          ofClass:(NSString*)class
{
    NSMutableDictionary*		classDesc;
    NSMutableDictionary*		fields;
    NSString*					stringValue;
    
    classDesc = [ classDescDict objectForKey:class ];
    ASSERT (classDesc != nil);
    
    fields = [ classDesc objectForKey:@"fields" ];
    ASSERT (fields != nil);
    
    stringValue = [ fields objectForKey:field ];
        
    return [ self stringToBool:stringValue ];
}

- (NSString*) boolToString:(BOOL)value
{
    if (value == YES)
        return NSStringTrue;
    else if (value == NO)
        return NSStringFalse;
    else
        { ASSERT ("boolToString: Not a boolean!!" == 0); return nil; }
}

- (BOOL) stringToBool:(NSString*)string
{
    if (string == NSStringTrue)
        return YES;
    else if (string == NSStringFalse)
        return NO;
    else
        { ASSERT ("stringToBool: Not a boolean!!" == 0); return NO; }
}


/* Dead code, using CFPropertyListCreateDeepCopy()

- (CFTypeRef) createDeepCopy:(CFTypeRef)value
{
        CFTypeID	valueType;
        
        valueType = CFGetTypeID (value);
        
        if (CFDictionaryGetTypeID() == valueType) {
        
            NSMutableDictionary*		newDict;
            NSString*				   *keys;
            int 						numKeys;
            int							i;
        
            newDict = CFDictionaryCreateMutableCopy (kCFAllocatorDefault, 0, value);
            numKeys = CFDictionaryGetCount (newDict);
            if (numKeys == 0)
                return newDict;
            ASSERT (numKeys > 0);
            
            keys = (NSString**) malloc (numKeys * sizeof(*keys));
            ASSERT (keys != nil);
            
            CFDictionaryGetKeysAndValues (
                newDict,
                (void**)keys,
                nil
            );
            
            for (i = 0; i < numKeys; i++) {
            
                NSString* 	key;
                CFTypeRef   	value;
                CFTypeID        type;
                
                key = keys[i];
                value = CFDictionaryGetValue (newDict, key);
                ASSERT (value != nil);
                
                type = CFGetTypeID (value);
                if (CFDictionaryGetTypeID() == type ||
                    CFArrayGetTypeID() == type) {
                
                    value = [ self createDeepCopy:value ];
                    fprintf (stderr, "deep copy dict element: new=0x%x\n", value);
                    CFDictionarySetValue (newDict, key, value);
                }
            }
            
            free (keys);
            return newDict;
        }
        else
        if (CFArrayGetTypeID() == valueType) {
            
            CFMutableArrayRef 	newArray;
            int 				numElements;
            int					i;
            
            newArray = CFArrayCreateMutableCopy (kCFAllocatorDefault, 0, value);
            
            numElements = CFArrayGetCount (newArray);
            if (numElements == 0)
                return newArray;
                        
            for (i = 0; i < numElements; i++) {
            
                CFTypeRef   	value;
                CFTypeID        type;
                
                value = CFArrayGetValueAtIndex (newArray, i);
                ASSERT (value != nil);
                
                type = CFGetTypeID (value);
                if (CFDictionaryGetTypeID() == type ||
                    CFArrayGetTypeID() == type) {
                
                    CFTypeRef oldValue = value;
                    value = [ self createDeepCopy:oldValue ];
                    ASSERT (oldValue != value);
                    fprintf (stderr, "deep copy array element: old=0x%x new=0x%x\n", oldValue, value);
                    CFArraySetValueAtIndex (newArray, i, value);
                    ASSERT (CFArrayGetValueAtIndex(newArray, i) == value);
                }
            }

            return newArray;
        }
        else {
        
            ASSERT ("createDeepCopy: unsupported type!!!" == 0);
            return nil;
        }
}
*/

@end
/*
static int _wasAutoReleased = 0;

@interface NSString (NSAutoreasingDebug)

- (void)release;
- (id)autorelease;

@end

@implementation NSString (NSAutoreasingDebug)
- (void)release
{
    if (_wasAutoReleased) {
    
        NSLog (@"released but already autoreleased");
        _wasAutoReleased = 0;
    }
    
    [ super release ];
}

- (id)autorelease
{
    _wasAutoReleased = 1;
    
    return [ super autorelease ];
}
@end
*/

//
// EOF
//