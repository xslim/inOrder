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
#include "config.h"

#import "EditPB.h"
#import "MyNSObject.h"
#import "Utilities.h"

@implementation EditPB

- (id) init
{
    ASSERT ("Please use initWithLoadSave!" == 0);
    return nil;
}

// initialization
- (id) initWithLoadSave:(LoadSavePB*)inLoadSave
{
    self = [ super init ];
    ASSERT (self != nil);
    
    // init instance vars
    _loadSave = inLoadSave;
    [ _loadSave retain ];
        
    _root = [ _loadSave getLinkedGraph ];
    ASSERT (_root != nil);
        
    _target = [ self getObjectAtPath:[ self createPath:@"targets", @"0", nil ] ];
    //if (_target == nil)
       // fprintf (stderr, "-[EditPB initWithLoadSave:] warning: no targets in project\n");
    
    _objectStack = [ [ NSMutableArray alloc ] init ];
    ASSERT(_objectStack != nil);
    
    // end init instance vars

    return self;
}

- (void)dealloc
{
    [ _loadSave autorelease ];
	[ super dealloc ];
}

- (NSString*) createPath:(NSString*)first,...
{
    va_list		args;
    NSString	*arg;
    NSString	*result;
    
    va_start (args, first);
    result = first;
    arg = va_arg (args, NSString*);
    while (arg != nil) {
    
        result = [ result stringByAppendingFormat:@"%@%@",kPathDelim,arg ];
        arg = va_arg (args, NSString*);
    }
    
    [ result retain ];
    
    return result;
}

- (NSString*) createPathWithArray:(NSArray*)components
{
    NSString	*path;
    int			i;
    
    ASSERT ([ components count ] > 0);
    
    path = @"";
    path = [ path stringByAppendingString: [ components objectAtIndex:0 ] ];
    for (i = 1; i < [ components count ]; i++) {
    
        path = [ path stringByAppendingFormat:@"%@%@", 
            kPathDelim, [ components objectAtIndex:i ] ];
    }
    
    [ path retain ];

    return path;
}


// This sure is a lot of screwing around just to split up a path
// callers should interpret a null parent to be the root
- (NSString*) parentPathOfPath:(NSString*)path
                      outChild:(NSString**)outChild
{
    NSArray*			pathParts;
    NSMutableArray* 	parentParts;
    NSString*			parentPath;
    
    ASSERT (path != nil);
    
    pathParts = [ path componentsSeparatedByString:kPathDelim ];
    ASSERT (pathParts != nil);
    
    parentParts = [ NSMutableArray arrayWithArray:pathParts ];
    ASSERT (parentParts != nil);
    
    if (outChild != nil) {
        
        *outChild = [ parentParts lastObject ];
        [ *outChild retain ];
    }
    
    if ([ parentParts count ] == 1) {
    
        parentPath = nil;
    }
    else {
    
        [ parentParts removeObjectAtIndex:[ parentParts count ] - 1 ];
        
        parentPath = [ self createPathWithArray:parentParts ];
    }
    
    return parentPath;
}


- (id) findObjectWithKey:(NSString*)key 
                matching:(NSString*)pattern
              startingAt:(id)rootObject
                maxDepth:(int)maxDepth;
{
    ASSERT (key != nil && pattern != nil && rootObject != nil);
    
    if (maxDepth == 0)
        return nil;

    [ _objectStack addObject:rootObject ];
    
    //NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ];
    
	//
	// Drill down to find an NSDictionary that contains a key matching
	// the given pattern. Do a breadth-first search. That is, scan all
	// keys of a dictionary before following children.
	//
    if ([ rootObject isKindOfClass:[ NSDictionary class ] ]) {

		// scan a dictionary
		NSEnumerator*	keysEnum;
		NSString*		dictKey;

		keysEnum = [ rootObject keyEnumerator ];
		
		id object;
		NSMutableArray* children = [ NSMutableArray array ];
				
		while (dictKey = [ keysEnum nextObject ]) {
		
			object = [ rootObject objectForKey:dictKey ];
				
			if ( [ key isEqualToString:dictKey ]) {
			
				if ([ object isKindOfClass:[ NSString class ] ] &&
				    [ pattern isEqualToString:object ] ) {
			
					// found it!		
					//[ pool release ];
					[ _objectStack removeLastObject ];
					return rootObject;
				}
			}
			else
			if ([ object isKindOfClass:[ NSDictionary class ] ] ||
				[ object isKindOfClass:[ NSArray class ] ]) {
			
				// add to list for recursive step
				ASSERT(object != nil);
				[ children addObject:object ];
			}
			else
				ASSERT("Unknown object type!");
		}
		
		//
		// Process children
		//
		NSEnumerator* childEnum = [ children objectEnumerator ];
		
		while (object = [ childEnum nextObject ]) {
		
			if (! [ _objectStack containsObject: object ]) {
			
				id foundObject = [ self findObjectWithKey:key 
					matching:pattern startingAt:object maxDepth:maxDepth-1 ];
				
				if (foundObject) {
				
				    [ _objectStack removeLastObject ];
					return foundObject;
				}
			}
		}
	}
    else if ([ rootObject isKindOfClass:[ NSArray class ] ]) {
    
        int		numElements;
        int		i;
        
        numElements = [ rootObject count ];

        for (i = 0; i < numElements; i++) {
        
            id object = [ rootObject objectAtIndex:i ];
            
            if ([ object isKindOfClass:[ NSDictionary class ] ] ||
                [ object isKindOfClass:[ NSArray class ] ]) {
                
                if (! [ _objectStack containsObject:object ]) {
				
                    id foundObject = [ self findObjectWithKey:key 
                        matching:pattern startingAt:object maxDepth:maxDepth-1 ];
                
					if (foundObject != nil) {
						//[ pool release ];
						[ _objectStack removeLastObject ];
						return foundObject;
					}
				} 
            }
        }
    }
    else {
    
        // doh!
        ASSERT ("Unknown Object Type!");
    }
    
    [ _objectStack removeLastObject ];
    //[ pool release ];
    return nil;
}

- (id) findObjectWithKey:(NSString*)key 
                matching:(NSString*)pattern 
              startingAt:(id)root
{
    return [ self findObjectWithKey:key 
        matching:pattern startingAt:root maxDepth:-1 ];
}

- (id) getObjectAtPath:(NSString*)path
{
    id	object = nil;
    
    // if path is null, return the root object
    if (path == nil)
        object = _root;
    else
		object = [ self getObjectAtPath:path relativeTo:_root ];
		    
    return object;
}

- (id) getObjectAtPath:(NSString*)path 
		   relativeTo:(id)object
{
	NSArray*		pathParts;
    int				numParts;
    int				i;
	
	ASSERT(path && object);
	
	pathParts = [ path componentsSeparatedByString:kPathDelim ];
	ASSERT (pathParts != nil);
	
	numParts = [ pathParts count ];
	ASSERT (numParts > 0);
	
	if (object == nil)
		object = _root; // start at the root (duh)
	
	for (i = 0; i < numParts && object != nil; i++) {
	
		NSString* 	part;
		
		part = [ pathParts objectAtIndex:i ];
		
		if ([ object isKindOfClass:[ NSDictionary class ] ]) {
		
			object = [ object objectForKey:part ];
		}
		else if ([ object isKindOfClass:[ NSArray class ] ]) {
		
			int i;
			
			// convert the path component to an integer
			i = [ part intValue ];
			if (i < [ object count ]) {                 
				object = [ object objectAtIndex:i ];
			}
			else {
				object = nil;
				return nil;
			}
		}
		else if (i != numParts) {
			// error, object has no subobjects, can't continue
			ASSERT ("No subobjects, invalid path!" == 0);
		}
	}
    
    // check if object was found or not
    ASSERT (i == numParts || path == nil);
    
    // in case I want a warning instead later
    if (i < numParts) {
    
         fprintf(stderr, "Value was not found\n");
    }
	
	return object;
}

- (id) addObjectAtPath:(NSString*)path
                object:(id)object
{
    NSString*		parentPath;
    NSString*		childPath;
    id				parent;
    id				oldObject;
    	
    parentPath = [ self parentPathOfPath:path outChild:&childPath ];
    
    parent = [ self getObjectAtPath:parentPath ];
    ASSERT (parent != nil);

    if ([ parent isKindOfClass:[ NSDictionary class ] ]) {

        oldObject = [ parent objectForKey:childPath ];
        if (oldObject != nil) {
            [ oldObject retain ];
        }
        [ parent setObject:object forKey:childPath ];
    }
    else if ([ parent isKindOfClass:[ NSArray class ] ]) {
    
        int i;
                
        // convert the childPath to an integer
        i = [ childPath intValue ];
        
        if (0 <= i && i < [ parent count ]) {
            oldObject = [ parent objectAtIndex:i ];
            if (oldObject != nil) {
                [ oldObject retain ];
            }
            [ parent replaceObjectAtIndex:i withObject:object ];
        }
        else {
            //fprintf (stderr, "addObjectAtPath: Index out of range, appending instead\n");
            oldObject = nil;
            [ parent addObject:object ];
        }
    }
    else {
    
        // error, not a plist collection type!
        oldObject = nil;
        ASSERT ("addObjectAtPath: Internal component not an array or dictionary" == 0);
    }
    
    return oldObject;
}   


- (id) removeObjectAtPath:(NSString*)path
{
    NSString*		parentPath;
    NSString*		childPath;
    id				parent;
    id				oldObject;
    	
    parentPath = [ self parentPathOfPath:path outChild:&childPath ];
    
    parent = [ self getObjectAtPath:parentPath ];

    if ([ parent isKindOfClass:[ NSDictionary class ] ]) {

        oldObject = [ parent objectForKey:childPath ];
        if (oldObject != nil) {
            [ oldObject retain ];
        }
        [ parent removeObjectForKey:childPath ];
    }
    else if ([ parent isKindOfClass:[ NSArray class ] ]) {
    
        int i;
                
        // convert the childPath to an integer
        i = [ childPath intValue ];
        
        if (0 <= i && i < [ parent count ]) {
            oldObject = [ parent objectAtIndex:i ];
            if (oldObject != nil) {
                [ oldObject retain ];
            }
            [ parent removeObjectAtIndex:i ];
        }
        else {
            fprintf (stderr, "removeObjectAtPath: Index out of range, can't remove\n");
            oldObject = nil;
        }
    }
    else {
    
        // error, not a plist collection type!
        oldObject = nil;
        ASSERT ("removeObjectAtPath: Value not a plist collection type" == 0);
    }

    return oldObject;
}




#pragma mark Files and Groups


- (PBXObject) createGroupWithPath:(NSString*)path
                          refType:(PBXRefType)refType
{
    NSString*   name;
    
    // get the name of the file
    name = [ path lastPathComponent ];

    return [ self createGroupWithName:name path:path refType:refType ];
}


- (PBXObject) createGroupWithName:(NSString*)name
{
    return [ self createGroupWithName:name path:nil refType:RT_GROUP_RELATIVE ];
}


- (PBXObject) createGroupWithName:(NSString*)name path:(NSString*)path refType:(PBXRefType)refType
{
    PBXObject 	groupObject;
    NSString* 	refTypeString;
    
    ASSERT (name != nil);
    
    groupObject = [ _loadSave createObjectWithClassName:@"PBXGroup" ];
    ASSERT (groupObject != nil);
    
    // create a new children array for example object
    {
        NSMutableArray* children;
        
        [ groupObject removeObjectForKey:@"children" ];

        children = [ NSMutableArray array ];
        ASSERT (children != nil);
        
        [ groupObject setObject:children forKey:@"children" ];
    }
    
    [ groupObject setObject:name forKey:@"name" ];
    if (path != nil)
        [ groupObject setObject:path forKey:@"path" ];
    
    refTypeString = [ NSString stringWithFormat:@"%d",refType ];
    [ groupObject setObject:refTypeString forKey:@"refType" ];
    
    return groupObject;
}


- (PBXObject) createFile:(NSString*)path
                 refType:(PBXRefType)refType
{
    PBXObject 	fileObject;
    NSString* 	refTypeString;
    NSString*	name;
    
    
    if ([ path hasSuffix:@".framework" ]) {
        fileObject = [ _loadSave createObjectWithClassName:@"PBXFrameworkReference" ];    
    }
    else
    if ([ path hasSuffix:@".a" ]) {
#if XCODE
        fileObject = [ _loadSave createObjectWithClassName:@"PBXFileReference" ];
#else        
        fileObject = [ _loadSave createObjectWithClassName:@"PBXLibraryReference" ];
#endif    
    }
    else {
        fileObject = [ _loadSave createObjectWithClassName:@"PBXFileReference" ];
    }
    ASSERT (fileObject != nil);
    
#if XCODE
    [ fileObject removeObjectForKey:@"expectedFileType" ];
    [ fileObject removeObjectForKey:@"lastKnownFileType" ];
#endif

    // get the name of the file
    name = [ [ path lastPathComponent ] retain ];
    [ path retain ];
    
    [ fileObject setObject:name forKey:@"name" ];
    [ fileObject setObject:path forKey:@"path" ];
        
    refTypeString = [ NSString stringWithFormat:@"%d", refType ];
    [ fileObject setObject:refTypeString forKey:@"refType" ];
    
    return fileObject;
}


- (void) addGroup:(PBXObject)group
          toGroup:(PBXObject)parentGroup
{
    NSMutableArray*		children;
    
    ASSERT (group != nil);
    
    if (parentGroup == nil) {
    
        parentGroup = [ self getObjectAtPath:@"mainGroup" ];
        ASSERT (parentGroup != nil);
    }

    children = [ parentGroup objectForKey:@"children" ];
    //ASSERT (children != nil);
    // Xcode: group objects can have no children key, whereas
    // they had an empty children array in PBX
    if (children == nil) {
    
        children = [ NSArray array ];
        [ parentGroup setObject:children forKey:@"children" ];
    }
    
    //NSLog (@"%@", children);
    //ASSERT ( [ children isKindOfClass:[ NSMutableArray class ] ] );
    
    [ children addObject:group ];
}

- (void) addFile:(PBXObject)ref
         toGroup:(PBXObject)parentGroup
{
    // same as addGroup! create [ addThing:toGroup ] ?
    [ self addGroup:ref toGroup:parentGroup ];
}



- (PBXObject) getChildOfGroup:(PBXObject)parentGroup named:(NSString*)childName
{
    // could use bsearch here, but not necessarily sorted, soo..
    NSMutableArray*		children;
    int						i;
    
    if (parentGroup == nil) {
    
        parentGroup = [ self getObjectAtPath:@"mainGroup" ];
        ASSERT (parentGroup != nil);
    }
    
    children = [ parentGroup objectForKey:@"children" ];
    ASSERT (children != nil);
    
    for (i = 0; i < [ children count ]; i++) {
    
        PBXObject	child;
        
        child = [ children objectAtIndex:i ];
        
        if ([ childName compare: [ child objectForKey:@"name" ] ] == NSOrderedSame) {
            
            return child;
        }
    }
    
    return nil;
}

- (PBXObject) getRootGroup
{
    PBXObject rootGroup = [ self getObjectAtPath:@"mainGroup" ];
    ASSERT (rootGroup != nil);
    
    return rootGroup;
}

static int compareByName (id o1, id o2, void *userData) {

    NSMutableDictionary		*d1, *d2;
    NSString				*s1, *s2;
    
    d1 = (NSMutableDictionary*)o1;
    d2 = (NSMutableDictionary*)o2;
    
    s1 = [ d1 objectForKey:@"name" ];
    s2 = [ d2 objectForKey:@"name" ];
    
    ASSERT (s1 != nil && s2 != nil);
    
    return [ s1 compare:s2 ];
}


- (void) sortGroupByName:(PBXObject)group
{
    NSMutableArray*		children;
    NSArray*			newArray;
    
    if (group == nil) {
    
        group = [ self getObjectAtPath:@"mainGroup" ];
        ASSERT (group != nil);
    }
    
    children = [ group objectForKey:@"children" ];
    ASSERT (children != nil);
    
    newArray = [ children sortedArrayUsingFunction:compareByName context:nil ];
    [ children removeAllObjects ];
    [ children addObjectsFromArray:newArray ];
}

#pragma mark Targets

- (PBXObject) currentTarget
{
    ASSERT (_target == nil || [ _target isKindOfClass:[ NSMutableDictionary class ] ]);
    return _target;
}

- (void) setCurrentTarget:(PBXObject)newTarget
{
    ASSERT (newTarget == nil || [ newTarget isKindOfClass:[ NSMutableDictionary class ] ]);
    _target = newTarget;
}

- (PBXObject) createBuildFile:(PBXObject)fileRef
{
    PBXObject 		 buildFileObject;
    
    buildFileObject = [ _loadSave createObjectWithClassName:@"PBXBuildFile" ];
    ASSERT (buildFileObject != nil);
    
    [ buildFileObject setObject:fileRef forKey:@"fileRef" ];
        
    return buildFileObject;
}

#ifdef XCODE
// note: private method, as it should be
- (PBXObject) createNativeTarget:(NSString*)name
                        withType:(NSString*)type
{
    NSArray         *root;
    PBXObject       targetObject;
    PBXObject       targetFileRefObject;
    PBXObject       productGroup;
    
	//
	// All "native" targets have class type PBXNativeTarget, they are given
	// a product type e.g. "com.apple.product-type.framework".
	//
    root = [ _loadSave objectRoot ];

    targetObject = [ self findObjectWithKey:@"productType" matching:type startingAt:root ];
    ASSERT (targetObject != nil);
    
    targetObject = [ Utilities mutablePlistDeepCopyDictionary:targetObject ];
    ASSERT (targetObject != nil);
    
    [ targetObject setObject:name forKey:@"name" ];
    [ targetObject setObject:name forKey:@"productName" ];
    
    targetFileRefObject = [ _loadSave createObjectWithClassName:@"PBXFileReference" ];
	
    // special case: make target name "name Framework" for frameworks
    if ([ type compare:@"com.apple.product-type.framework" ] == NSOrderedSame) {
    
        NSString *targetName = [ NSString stringWithFormat:@"%@ Framework", name, nil ];
        
        [ targetObject setObject:targetName forKey:@"name" ];
    }
    
    [ targetFileRefObject setObject:name forKey:@"path" ];
	
	//[ [ targetObject objectForKey:@"buildSettings" ] setObject:name forKey:@"PRODUCT_NAME" ];

     // remove any files from the target's build phases
    {
        int i;
        NSMutableArray*	phases;
        
        phases = [ targetObject objectForKey:@"buildPhases" ];
        for (i = 0; i < [ phases count ]; i++) {
        
            NSMutableArray*	files;
            
            files = [ [ phases objectAtIndex:i ] objectForKey:@"files" ];
                
            [ files removeAllObjects ];
        }
    }
    
    // remove any dependent targets
    {
        NSMutableArray*	dependencies;
        
        dependencies = [ targetObject objectForKey:@"dependencies" ];
        ASSERT (dependencies != nil);
        
        [ dependencies removeAllObjects ];
    }
    
    // add targetFileRef to the target
    [ targetObject setObject:targetFileRefObject forKey:@"productReference" ];
    
    // add the target to the project target list
    [ self addObjectAtPath:[ self createPath:@"targets", @"-1", nil ] object:targetObject ];
    
    // add the targetFileRef to the project file list
    productGroup = 
        [ self findObjectWithKey:@"name"
                        matching:@"Products"
                     startingAt:
                        [ self getObjectAtPath:
                            [ self createPath:@"mainGroup", @"children", nil ] ]
                        maxDepth:2 ];
    
    if (productGroup == nil) {
        // printf ("-[EditPB createTarget:withClass:withFileClass: ] no \"Products\" group found, creating it for you.\n");
        productGroup = [ self createGroupWithName:@"Products" ];
        [ self addGroup:productGroup toGroup:nil ];
    }
    [ self addFile:targetFileRefObject toGroup:productGroup ];
    
	// set the product name build setting
	PBXObject saveTarget = [ self currentTarget ];
	[ self setCurrentTarget:targetObject ];
	[ self setBuildSetting:@"PRODUCT_NAME" toValue:name ];
	[ self setCurrentTarget:saveTarget ];
	
    return targetObject;
}
#endif // XCODE

// note: private method
- (PBXObject) createTarget:(NSString*)name 
                 withClass:(NSString*)class 
             withFileClass:(NSString*)fileClass
{
    PBXObject	targetObject;
    PBXObject	targetFileRefObject;
    PBXObject	productGroup;
    
    targetObject = [ _loadSave createObjectWithClassName:class ];
    ASSERT (targetObject != nil);
    
    [ targetObject setObject:name forKey:@"name" ];
    [ targetObject setObject:name forKey:@"productName" ];
    
    targetFileRefObject = [ _loadSave createObjectWithClassName:fileClass ];
    ASSERT (targetFileRefObject != nil);
    
    // special case: make target name "name Framework" for frameworks
    if ([ class compare:@"PBXFrameworkTarget" ] == NSOrderedSame) {
    
        NSString *targetName = [ NSString stringWithFormat:@"%@ Framework", name, nil ];
        
        [ targetObject setObject:targetName forKey:@"name" ];
    }
    
    [ targetFileRefObject setObject:name forKey:@"path" ];
    [ [ targetObject objectForKey:@"buildSettings" ] setObject:name forKey:@"PRODUCT_NAME" ];
    
    // remove any files from the target's build phases
    {
        int i;
        NSMutableArray*	phases;
        
        phases = [ targetObject objectForKey:@"buildPhases" ];
        for (i = 0; i < [ phases count ]; i++) {
        
            NSMutableArray*	files;
            
            files = [ [ phases objectAtIndex:i ] objectForKey:@"files" ];
                
            [ files removeAllObjects ];
        }
    }
    
    // remove any dependent targets
    {
        NSMutableArray*	dependencies;
        
        dependencies = [ targetObject objectForKey:@"dependencies" ];
        ASSERT (dependencies != nil);
        
        [ dependencies removeAllObjects ];
    }
    
    // add targetFileRef to the target
    [ targetObject setObject:targetFileRefObject forKey:@"productReference" ];
    
    // add the target to the project target list
    [ self addObjectAtPath:[ self createPath:@"targets", @"-1", nil ] object:targetObject ];
    
    
    // add the targetFileRef to the project file list
    productGroup = 
        [ self findObjectWithKey:@"name"
                        matching:@"Products"
                     startingAt:
                        [ self getObjectAtPath:
                            [ self createPath:@"mainGroup", @"children", nil ] ]
                        maxDepth:2 ];
    
    if (productGroup == nil) {
        // printf ("-[EditPB createTarget:withClass:withFileClass: ] no \"Products\" group found, creating it for you.\n");
        productGroup = [ self createGroupWithName:@"Products" ];
        [ self addGroup:productGroup toGroup:nil ];
    }
    [ self addFile:targetFileRefObject toGroup:productGroup ];
    
    return targetObject;
}

- (PBXObject) createApplicationTarget:(NSString*)name
{
#if XCODE
    return [ self createNativeTarget:name withType:@"com.apple.product-type.application" ];
#else
    return [ self createTarget:name withClass:@"PBXApplicationTarget" withFileClass:@"PBXApplicationReference" ];
#endif
}

- (PBXObject) createStaticLibraryTarget:(NSString*)name
{
#if XCODE
    return [ self createNativeTarget:name withType:@"com.apple.product-type.library.static" ];
#else
    PBXObject target = [ self createTarget:name withClass:@"PBXLibraryTarget" withFileClass:@"PBXLibraryReference" ];
    PBXObject saveTarget = [ self currentTarget ];
    [ self setCurrentTarget:target ];
    [ self setBuildSetting:@"LIBRARY_STYLE" toValue:@"STATIC" ];
    [ self setCurrentTarget:saveTarget ];
    return target;
#endif
}

- (PBXObject) createDynamicLibraryTarget:(NSString*)name
{
#if XCODE
    return [ self createNativeTarget:name withType:@"com.apple.product-type.library.dynamic" ];
#else
    PBXObject target = [ self createTarget:name withClass:@"PBXLibraryTarget" withFileClass:@"PBXLibraryReference" ];
    PBXObject saveTarget = [ self currentTarget ];
    [ self setCurrentTarget:target ];
    [ self setBuildSetting:@"LIBRARY_STYLE" toValue:@"DYNAMIC" ];
    //[ self setBuildSetting:@"INSTALL_PATH" toValue:@"@executable_path/" ];
    [ self setCurrentTarget:saveTarget ];
    return target;
#endif
}

- (PBXObject) createToolTarget:(NSString*)name
{
#if XCODE
    return [ self createNativeTarget:name withType:@"com.apple.product-type.tool" ];
#else    
    return [ self createTarget:name withClass:@"PBXToolTarget" withFileClass:@"PBXExecutableFileReference" ];
#endif
}

- (PBXObject) createFrameworkTarget:(NSString*)name
{
#if XCODE
    return [ self createNativeTarget:name withType:@"com.apple.product-type.framework" ];
#else
    return [ self createTarget:name withClass:@"PBXFrameworkTarget" withFileClass:@"PBXFrameworkReference" ];
#endif
}

- (PBXObject) createAggregateTarget:(NSString*)name
{
    PBXObject targetObject;
    
    targetObject = [ _loadSave createObjectWithClassName:@"PBXAggregateTarget" ];
    ASSERT (targetObject != nil);
    
    [ targetObject setObject:name forKey:@"name" ];
    
    // remove any dependent targets
    {
        NSMutableArray*	dependencies;
        
        dependencies = [ targetObject objectForKey:@"dependencies" ];
        ASSERT (dependencies != nil);
        
        [ dependencies removeAllObjects ];
    }
    
    // prepend target to list of targets
    {
        NSMutableArray* targets;
        targets = [ self getObjectAtPath:[ self createPath:@"targets", nil ] ];
        ASSERT(targets != nil);
        
        [ targets insertObject:targetObject atIndex:0 ];
    }
    
    return targetObject;
}

- (PBXObject) createShellScriptBuildPhase:(NSString*)shellScript
{
    PBXObject buildPhase;
    
    buildPhase = [ _loadSave createObjectWithClassName:@"PBXShellScriptBuildPhase" ];
    ASSERT(buildPhase != nil);
    
    [ buildPhase setObject:@"/bin/sh" forKey:@"shellPath" ];
    [ buildPhase setObject:shellScript forKey:@"shellScript" ];
    
    return buildPhase;
}

// note: private method
// hmm, is this method name long enough? ;-)
- (id) locateBuildPhaseFilesWithBuildPhaseName:(NSString*)name
{
    id	 	  buildPhases;
    PBXObject buildPhase;
    
    // get the array of build phases
    buildPhases = [ [ self currentTarget ] objectForKey:@"buildPhases" ];
    ASSERT (buildPhases != nil);
    
    // locate the build phase
    buildPhase = [ self findObjectWithKey:@"isa" 
                                 matching:name
                               startingAt:buildPhases
                                 maxDepth:2 ];
                
    if (buildPhase == nil)
        return nil;

    return [ buildPhase objectForKey:@"files" ];
}


// note: private method
- (void) addFile:(PBXObject)fileRef toBuildPhase:(NSString*)phase
{
    NSMutableArray*		buildPhaseFiles;
    PBXObject				buildFile;
    
    buildPhaseFiles = (NSMutableArray*)
        [ self locateBuildPhaseFilesWithBuildPhaseName:phase ];
    
    if (buildPhaseFiles == nil) {
        fprintf (stderr, 
                 "-[ EditPB addFileToBuildPhase: ] " 
                 " can't find phase \"%s\", it is probably illegal for current target\n",
                 [ phase cString ]);
        return;
    }
    
    buildFile = [ self createBuildFile:fileRef ];
    ASSERT (buildFile != nil);
    
    [ buildPhaseFiles addObject:buildFile ];
}

- (void) addHeaderFile:(PBXObject)fileRef
{
    [ self addFile:fileRef toBuildPhase:@"PBXHeadersBuildPhase" ];
}

- (void) addSourceFile:(PBXObject)fileRef
{
    [ self addFile:fileRef toBuildPhase:@"PBXSourcesBuildPhase" ];
}

- (void) addResourceFile:(PBXObject)fileRef
{
    [ self addFile:fileRef toBuildPhase:@"PBXResourcesBuildPhase" ];
}

- (void) addFrameworkFile:(PBXObject)fileRef
{
    [ self addFile:fileRef toBuildPhase:@"PBXFrameworksBuildPhase" ];
}


- (void) addDependentTarget:(PBXObject)targetRef;
{
    PBXObject			depObject;
    NSMutableArray*	dependencies;
    
    dependencies = [ [ self currentTarget ] objectForKey:@"dependencies" ];
    ASSERT (dependencies != nil);
    
    depObject = [ _loadSave createObjectWithClassName:@"PBXTargetDependency" ];
    ASSERT (depObject != nil);
    
#if XCODE
    PBXObject       proxyObject;
    
    // fix the reference back to the project root
    proxyObject = [ self findObjectWithKey:@"isa" matching:@"PBXContainerItemProxy" startingAt:depObject ];
    ASSERT (proxyObject != nil);
    
    [ proxyObject setObject:_root forKey:@"containerPortal" ];
#endif

    [ depObject setObject:targetRef forKey:@"target" ];
    
    [ dependencies addObject:depObject ];
}

- (void) addShellScriptBuildPhase:(PBXObject)shellScriptBuildPhase
{
    NSMutableArray *targetBuildPhases;
    
    targetBuildPhases = [ [ self currentTarget ] objectForKey:@"buildPhases" ];
    
    [ targetBuildPhases addObject:shellScriptBuildPhase ];
}

- (PBXObject) getProductRef:(PBXObject)targetRef
{
    PBXObject target;
    
    if (targetRef == nil)
        target = [ self currentTarget ];
    else
        target = targetRef;

    return [ target objectForKey:@"productReference" ];
}



#pragma mark Build Settings

#if XCODE >= 3

- (PBXObject) getDebugBuildSettings
{
	// XCODE 3.x has the following setup:
	//
	// Target[buildConfigurationList][N][name] = "Debug" or "Release";
	//
	// Target[buildConfigurationList][N][buildSettings][Setting Key] = Setting Value;
	//
	// Where N is the configuration number (0 seems to be debug, 1 is release)
	//
	return [ self getObjectAtPath:[self createPath:@"buildConfigurationList", @"buildConfigurations", @"0", @"buildSettings", nil ] 
		relativeTo:[ self currentTarget ] ];
}

- (PBXObject) getReleaseBuildSettings
{
	return [ self getObjectAtPath:[self createPath:@"buildConfigurationList", @"buildConfigurations", @"1", @"buildSettings", nil ] 
		relativeTo:[ self currentTarget ] ];
}


// note: private method
- (PBXObject) getBuildSettings
{
	return [ self getReleaseBuildSettings ];    
}


#else

// note: private method
- (PBXObject) getBuildSettings
{
	return [ [ self currentTarget ] objectForKey:@"buildSettings" ];    
}

#endif



// general build setting interface
- (NSString*) getBuildSetting:(NSString*)name
{
    PBXObject	buildSettings;
        
    buildSettings = [ self getBuildSettings ];
    ASSERT (buildSettings != nil);
    
    return [ buildSettings objectForKey:name ];
}

- (void) setBuildSetting:(NSString*)name toValue:(NSString*)value
{
    PBXObject	buildSettings;
#if XCODE >= 3
	buildSettings = [ self getDebugBuildSettings ];
	[ buildSettings setObject:value forKey:name ];
	
	buildSettings = [ self getReleaseBuildSettings ];
	[ buildSettings setObject:value forKey:name ];
#else
    buildSettings = [ self getBuildSettings ];
    ASSERT (buildSettings != nil);
    
    [ buildSettings setObject:value forKey:name ];
#endif
}

- (void) appendToBuildSetting:(NSString*)name value:(NSString*)appendValue
{
    PBXObject		buildSettings;
    NSString*		oldSetting;
    NSString*		newSetting;
        
    buildSettings = [ self getBuildSettings ];
    ASSERT (buildSettings != nil);
    
    oldSetting = [ buildSettings objectForKey:name ];
    if (oldSetting != nil && NSOrderedSame != [ oldSetting compare:@"" ]) {
    
        newSetting = [ oldSetting stringByAppendingFormat:@" %@", appendValue ];
    }
    else {
    
        newSetting = appendValue;
    }
    
    [ buildSettings setObject:newSetting forKey:name ];
}

- (void) appendToBuildSettingArray:(NSString*)name value:(NSString*)appendValue
{
    PBXObject		buildSettings;
    NSArray*		oldSetting;
    NSArray*		newSetting;
        
    buildSettings = [ self getBuildSettings ];
    ASSERT (buildSettings != nil);
    
    oldSetting = [ buildSettings objectForKey:name ];
    if (oldSetting != nil) {
    
        newSetting = [ oldSetting arrayByAddingObject:appendValue ];
    }
    else {
    
        newSetting = [ NSArray arrayWithObject:appendValue ];
    }
    
    [ buildSettings setObject:newSetting forKey:name ];
}

- (NSString*)getHeaderSearchPaths
{
    return [ self getBuildSetting:@"HEADER_SEARCH_PATHS" ];
}

- (void) setHeaderSearchPaths:(NSString*)paths
{
    [ self setBuildSetting:@"HEADER_SEARCH_PATHS" toValue:paths ];
}

- (void) addHeaderSearchPath:(NSString*)path
{
#if XCODE >= 3
    [ self appendToBuildSettingArray:@"HEADER_SEARCH_PATHS" value:path ];
#else
    [ self appendToBuildSetting:@"HEADER_SEARCH_PATHS" value:path ];
#endif
}

- (NSString*) getLibrarySearchPaths
{
    return [ self getBuildSetting:@"LIBRARY_SEARCH_PATHS" ];
}

- (void) setLibrarySearchPaths:(NSString*)paths
{
    [ self setBuildSetting:@"LIBRARY_SEARCH_PATHS" toValue:paths ];
}

- (void)addLibrarySearchPath:(NSString*)path
{
    [ self appendToBuildSetting:@"LIBRARY_SEARCH_PATHS" value:path ];
}

- (NSString*) getFrameworkSearchPaths
{
    return [ self getBuildSetting:@"FRAMEWORK_SEARCH_PATHS" ];
}

- (void) setFrameworkSearchPaths:(NSString*)paths
{
    [ self setBuildSetting:@"FRAMEWORK_SEARCH_PATHS" toValue:paths ];
}

- (void) addFrameworkSearchPath:(NSString*)path
{
    [ self appendToBuildSetting:@"FRAMEWORK_SEARCH_PATHS" value:path ];
}

- (NSString*) getOtherCFlags
{
    return [ self getBuildSetting:@"OTHER_CFLAGS" ];
}

- (void) setOtherCFlags:(NSString*)otherCFlags
{
    [ self setBuildSetting:@"OTHER_CFLAGS" toValue:otherCFlags ];
}

- (void) addOtherCFlag:(NSString*)otherCFlag
{
    [ self appendToBuildSetting:@"OTHER_CFLAGS" value:otherCFlag ];
}

- (NSString*) getOtherLDFlags
{
    return [ self getBuildSetting:@"OTHER_LDFLAGS" ];
}

- (void) setOtherLDFlags:(NSString*)otherLDFlags
{
    [ self setBuildSetting:@"OTHER_LDFLAGS" toValue:otherLDFlags ];
}

- (void) addOtherLDFlag:(NSString*)otherLDFlag
{
    [ self appendToBuildSetting:@"OTHER_LDFLAGS" value:otherLDFlag ];
}

#pragma mark Build Styles

- (NSArray*) getBuildStyles
{
    return [ self getObjectAtPath:@"buildStyles" ];
}

- (PBXObject) getBuildStyleWithName:(NSString*)name
{
    return [ self findObjectWithKey:@"name"
                           matching:name
                         startingAt:[ self getBuildStyles ]
                           maxDepth:2 ];
}

- (NSString*) formatBuildStyleString:(NSString*)string append:(BOOL)append
{
    if (string == nil)
        return nil;
    
    // The append values have \u0001 as the first character
    if (append) {
        if ( [ string characterAtIndex:0 ] != 0x1)
            return [ NSString stringWithFormat:@"%C%@", 0x1, string ];
        else
            return string;
    }
    else {
        if ( [ string characterAtIndex:0 ] == 0x1)
            return [ string substringFromIndex:1 ];
        else
            return string;
    }
}

- (NSString*) getBuildStyleValue:(PBXObject)buildStyle withName:(NSString*)name
{
    return [ self formatBuildStyleString:[ buildStyle objectForKey:name ] append:NO ];
}

- (void) setBuildStyleValue:(PBXObject)buildStyle withName:(NSString*)name toValue:(NSString*)value
{
    [ buildStyle setObject:
        [ self formatBuildStyleString:value 
            append:[ self getBuildStyleValueAppends:buildStyle withName:name ] ]
        forKey:name ];
}

- (BOOL) getBuildStyleValueAppends:(PBXObject)buildStyle withName:(NSString*)name
{
    NSString *string = [ buildStyle objectForKey:name ];
    if (string != nil)
        return [ string characterAtIndex:0 ] == 0x1;
    else
        return NO;
}

- (void) setBuildStyleValueAppends:(PBXObject)buildStyle withName:(NSString*)name toValue:(BOOL)value
{
    [ self setBuildStyleValue:buildStyle 
        withName:name
        toValue:[ self formatBuildStyleString:[ buildStyle objectForKey:name ]
            append:value ] ];
}

@end

//
// EOF
//