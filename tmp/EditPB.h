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

/*!
    @header 	EditPB
*/

#import "LoadSavePB.h"


#define kPathDelim @">>"

// these long names are killing my poor fingers, let's make a typedef
typedef NSMutableDictionary* PBXObject;


/*!
    @class 		EditPB
    @abstract	Property List editor for the Project Builder project format
*/
@interface EditPB : NSObject
{
    LoadSavePB			*_loadSave;
    PBXObject			_root;
    PBXObject			_target;		// current target we are focused on
	PBXObject           _config;        // current target config (currently debug or release) we are focused on
    NSMutableArray     *_objectStack;
}

/*!
    @enum PBXRefType
    @abstract Enumeration of file reference types.
    @discussion Project Builder supports several file reference types. When
        creating a file reference, you specify a path and a reference type
        that describes the kind of path.
    
    @constant RT_ABSOLUTE_PATH An absolute path, e.g. "/usr/include/stdio.h"
    @constant RT_PROJECT_RELATIVE A relative path, relative to the directory containing the .pbproj bundle, e.g. "./build/MyApp.app"
    @constant RT_BUILD_PRODUCT_RELATIVE A relative path, relative to the build products directory. PB lets you change the location
        of this directory, by default it is the "build" directory in the parent directory of the .pbproj bundle.
    @constant RT_GROUP_RELATIVE A relative path, relative to the containing group in the project. For this to work, PB must
        know the path of the containing group (or the path of the containing group's containing group, etc).
    @constant RT_SEARCH_PATH I don't know exactly what this means yet. If you do, let me know ;-)

*/
typedef enum {

    RT_ABSOLUTE_PATH    = 0,
    RT_PROJECT_RELATIVE = 2,
    RT_BUILD_RELATIVE   = 3,
    RT_GROUP_RELATIVE   = 4,
    RT_SEARCH_PATH      = 5
    
} PBXRefType;

/*!
    @method initWithLoadSave:
    @abstract Initializes the editor.
    @param loadSave An instance of LoadSavePB.
    @result The initialized object.
*/
- (id) initWithLoadSave:(LoadSavePB*)loadSave;

#pragma mark Paths

/*! 
    @method createPath:
    @abstract Creates a path that refers to an object in the graph.
    @param first A nil-terminated list of path components.
    @discussion This is a convenience function to create a path
        to a particular object in the graph. The path delimiter
        used is defined with the constant kPathDelim, and is subject to change
        (if for example, it conflicts with strings used in the graph).
        
        A path can reference any object in the graph, except the root.
        To indicate the root object, pass nil to routines that take a path
        as an argument.
        
        To reference an object of some key in a dictionary,
        use the key as a component, the dictionary name as the previous component, etc.
        
        To reference an object of an array, use an array index as the path component.
        
        Examples (note you should *not* use a slash as the delimiter, use kPathDelim):
        
        "mainGroup/targets/0/buildSettings/INSTALL_PATH" -> INSTALL_PATH build setting of first target
        "mainGroup/children/0/name" -> Name of the first group in the project.
        
    @result A kPathDelim-delimited path.
*/
- (NSString*) createPath:(NSString*)first,...;

/*! 
    @method createPathWithArray:
    @abstract Creates a path that refers to an object in the graph.
    @param components An array of path components.
    @discussion This has the same semantics as -createPath:.
    @result A kPathDelim-delimited path.
*/
- (NSString*) createPathWithArray:(NSArray*)components;

/*!
    @method parentOfPath:outChild:
    @abstract	Gets the parent of a given path.
    @param	path A path in the project graph.
    @param  outChild On return, contains the child (last part of the path).
                     Pass nil for this parameter if you don't care about the child.
    @discussion	The parent path is the path minus the last part of the path.
    @result The parent path of the given path, or nil if there is no parent.
*/
- (NSString*) parentPathOfPath:(NSString*)path outChild:(NSString**)outChild;

/*!
    @method findObjectWithKey:matching:startingAt:
    @abstract	Searches the graph for an object (NSDictionary) with the given key.
    @param key The key to search for.
    @param pattern The string the key references of the target object. At this time, this isn't really
        a pattern, but an exact match for a key's value.
    @param root An NSMutableArray or NSDictionary to start the search at. Pass nil to start at the root.
    @discussion This method searches the graph in breadth-first order. That is, all keys of a dictionary
        are checked against the pattern before descending to children dictionaries and arrays. If possible,
        try to se -getObjectAtPath instead, since this can have unusual results if not used carefully.
        For example, there are many keys called "name", many of which have the same value.
        
        Also, if you don't know the exact path to the object, narrow the search by specifying
        a known root object. This will greatly increase the accuracy of your search.
    @result The found object (NSMutableDictionary, NSMutableArray, or NSString), or nil if not found.
*/
- (id) findObjectWithKey:(NSString*)key matching:(NSString*)pattern startingAt:(id)root;

/*!
    @method findObjectWithKey:matching:startingAt:maxDepth
    @abstract	Searches the graph for an object (NSDictionary) with the given key.
    @param key The key to search for.
    @param pattern The string the key references of the target object. At this time, this isn't really
        a pattern, but an exact match for a key's value.
    @param root An NSMutableArray or NSDictionary to start the search at. Pass nil to start at the root.
    @param maxDepth The maximum search depth (greater than 0).
    @discussion This method is identical to findObjectWithKey:matching:startingAt with the addition
        of a search depth parameter. This is particularly useful if only a single array or dictionary
        is desired for the search.
    
    @result The found object (NSMutableDictionary, NSMutableArray, or NSString), or nil if not found.
*/
- (id) findObjectWithKey:(NSString*)key matching:(NSString*)pattern startingAt:(id)root maxDepth:(int)maxDepth;

/*! 
    @method getObjectAtPath:
    @abstract Gets an object in the graph at the given path.
    @param path The path the points to the object. Pass nil to get the root object.
        Create the path with -createPath: or -createPathWithArray:.
    @result The object at the given path, or nil if not found.
*/
- (id) getObjectAtPath:(NSString*)path;

/*! 
    @method getObjectAtPath:relativeTo:
    @abstract Gets an object in the graph at the given path.
    @param path The path the points to the object. Pass nil to get the root object.
        Create the path with -createPath: or -createPathWithArray:.
    @result The object at the given path, or nil if not found.
*/
- (id) getObjectAtPath:(NSString*)path relativeTo:(id)object;

/*!
    @method addObjectAtPath:object:
    @abstract Adds, or appends an object at the given path.
    @param path The path the references the parent object.
        Create the path with -createPath: or -createPathWithArray:.
    @param object The new object to add.
    @discussion If an object exists at the specified path,
    it will be retained, removed, and returned. Otherwise,
    nil will be returned.
    
    If the array index (the last component) of the path is out of bounds, the object
    will be appended to the array. For example, you can use -1 as the array
    index in order to append to an existing array.
    
    @result The removed object at the path, or nil if there is no prexisting object.
*/
- (id) addObjectAtPath:(NSString*)path object:(id)object;

/*!
    @method removeObjectAtPath:
    @abstract Removes the object at the given path.
    @param path The path to the object. Create the path with -createPath: or -createPathWithArray:.
    @result The object that was removed, or nil if not found. 
*/
- (id) removeObjectAtPath:(NSString*)path;

#pragma mark Files and Groups

/*!
    @method createGroupWithPath:refType:
    @abstract Creates a new group object that refers to a file system directory.
    @param path The file system path (slash-delimited) to the group.
    @param refType The kind of path.
    @discussion In the file hierarchy group objects
        are like the Finder's "folders". If you want to create
        group-relative children, you should create the group
        with this function. Group-relative paths are usually preferred since
        they make the resulting file size smaller.
        
        The name of the group is inferred from the path. The last component
        of the path will be used as the name.
        
        The group is only created. It is not added to the file hierarchy. Use
        -addGroup:toGroup: to place the group in the project.

        This only creates "normal" groups. Groups for localization (variant groups)
        and other features are not handled.
        
    @result The new group object.
*/
- (PBXObject) createGroupWithPath:(NSString*)path refType:(PBXRefType)refType;


/*!
    @method createGroupWithName:
    @abstract Creates a new group object with the given name.
    @param name The name of the new group.
    @discussion Unlike -createGroupWithPath:refType this group is merely a container
    for other groups and files, and does not contain a path. Therefore, children of this group
    should not use a group relative path.
    @result The new group object.
*/
- (PBXObject) createGroupWithName:(NSString*)name;

/*!
    @method createGroupWithName:path:refType
    @abstract Creates a new group object with the given name.
    @param name The name of the new group.
    @param path The path to the group. Can be nil.
    @param refType The type of path that is used. Use RT_GROUP_RELATIVE if path is nil.
    @discussion Unlike -createGroupWithPath:refType this allows you to have
        a name that is not necessarily derived from the path. The other createGroup*
        methods call this method to create groups.
    @result The new group object.
*/
- (PBXObject) createGroupWithName:(NSString*)name path:(NSString*)path refType:(PBXRefType)refType;

// PBXVariantGroup

/*!
    @method createFile:refType:
    @abstract Creates a new file reference.
    @param path The file system path to the file.
    @param refType The kind of path.
    @discussion The name of the file ref is the last path
        component of the path.
    
        For some files, the file type will be inferred from the
        file extension and treated specially. Therefore, you can use this method
        to create .nib, .framework, and other types of references.
    @result The new file reference.
*/
- (PBXObject) createFile:(NSString*)path refType:(PBXRefType)refType;
// TODO:
// 	PBXApplicationReference
//	PBXLibraryReference
//	PBXToolReference
//  others..?

/*!
    @method addGroup:toGroup:
    @abstract Adds a created group to the project.
    @param group The group to add.
    @param parentGroup The new parent group of the group to add. Pass nil
        to add to the root group.
    @discussion The group is added to the tail of the parent group. The parent group
        is not sorted or organized.
*/
- (void) addGroup:(PBXObject)group toGroup:(PBXObject)parentGroup;

/*!
    @method addFile:toGroup:
    @abstract Adds a created file ref to the project.
    @param fileRef The file ref, from -createFile:refType:.
    @param parentGroup The parent group to add the file to. Pass nil to add
        to the root group.
    @discussion The file is added to the end of the parent group.
        The parent group is not sorted or otherwise organized.
*/
- (void) addFile:(PBXObject)fileRef toGroup:(PBXObject)parentGroup;

/*!
    @method getChildOfGroup:named:
    @abstract Finds the child group or file of a group with the given name.
    @param parentGroup The group that is known to contain the child. Pass nil
        to use the root group. If a group contains multiple entries with the same name,
        this returns the first entry found.
    @param childName The name of the child.
    @discussion
    @result The child file ref or group, or nil if not found.
*/
- (PBXObject) getChildOfGroup:(PBXObject)parentGroup named:(NSString*)childName; 


/*!
    @method getRootGroup
    @abstract Returns the root group of the project.
    @discussion All projects contain a root group which is the root of the groups tree,
        and usually has the same name as the project (minus the .pbproj extension).
    @result The root group.
*/
- (PBXObject) getRootGroup;

/*!
    @method sortGroupByName:
    @abstract Sorts the entries in the given group.
    @param group The group to sort. Pass nil to sort the main/root group.
    @discussion The group is sorted alphabetically. Groups and files have the
    same sort order (i.e. groups don't sort before/after file refs).
*/
- (void) sortGroupByName:(PBXObject)group;


#pragma mark Targets
/*!
    @method	currentTarget:
    @abstract Gets the target set for editing.
    @discussion Methods that change target settings use
        the current target to determine what target to modify, rather
        than passing the target as an extra parameter.
        
        By default, the current target is set to the first target
        in the project.
    @result The current target. 
*/
- (PBXObject) currentTarget;

/*!
    @method setCurrentTarget:
    @abstract Sets the current target for editing.
    @param newTarget The new target to focus on.
        Pass nil to focus on the first target in the project.
*/
- (void) setCurrentTarget:(PBXObject)newTarget;


/*!
    @method createBuildFile:
    @abstract Creates a build phase file ref from a file ref.
    @discussion This is the object stored in a build phase. It contains a reference to the
        associated file. Normally the -addHeaderFile:. -addSourceFile:, and -addFrameworkFile: create this
        object for you.
    @result A new build file object.
*/
- (PBXObject) createBuildFile:(PBXObject)fileRef;	// 	PBXBuildFile

// 	PBXBuildStyle

// Targets
/*!
    @method createApplicationTarget:
    @abstract Creates an empty application target (.app bundle).
    @param name The name of the new target.
    @discussion A new target is created, and a file ref for its product 
        is added to the "Products" group, which will be created not available.
        Frameworks and libraries are not added.
    @result The new target.
*/
- (PBXObject) createApplicationTarget:(NSString*)name;	// 	PBXApplicationTarget


/*!
    @method createStaticLibraryTarget:
    @abstract Creates an empty static library target.
    @param name The name of the new target.
    @discussion A new target is created, and a file ref for its product 
        is added to the "Products" group, which will be created if not available.
        Frameworks and libraries are not added. 
    @result The new target.
*/
- (PBXObject) createStaticLibraryTarget:(NSString*)name;		//	PBXLibraryTarget

/*!
    @method createDynamicLibraryTarget:
    @abstract Creates an empty dynamic library target.
    @param name The name of the new target.
    @discussion A new target is created, and a file ref for its product 
        is added to the "Products" group, which will be created if not available.
        Frameworks and libraries are not added.
    @result The new target.
*/
- (PBXObject) createDynamicLibraryTarget:(NSString*)name;		//	PBXLibraryTarget

/*!
    @method createToolTarget:
    @abstract Creates an empty tool target (non-bundled executible).
    @param name The name of the new target.
    @discussion A new target is created, and a file ref for its product 
        is added to the "Products" group, which will be created not available.
        Frameworks and libraries are not added. 
    @result The new target.
*/
- (PBXObject) createToolTarget:(NSString*)name;			//	PBXToolTarget


/*!
    @method createFrameworkTarget:
    @abstract Creates an empty framework target (.framework bundle).
    @param name The name of the new target.
    @discussion A new target is created, and a file ref for its product 
        is added to the "Products" group, which will be created not available.
        Frameworks and libraries are not added. 
    @result The new target.
*/
- (PBXObject) createFrameworkTarget:(NSString*)name;	//	PBXFrameworkTarget

/*!
    @method createAggregateTarget:
    @abstract Creates an aggregate target.
    @param name The name of the target.
    @discussion A new target is created with the given name. This target
        type is most useful for creating a "label" target or "all" target.
        That is most often used to compile a collection of other targets (by making them
        all dependencies of the aggregate target).
    @result The new target.
*/
- (PBXObject) createAggregateTarget:(NSString*)name;	//	PBXAggregateTarget

/*!
    @method createShellScriptBuildPhase:
    @abstract Creates a shell script build phase.
    @param shellScript The shell script.
    @discussion A new shell script build phase is created. The /bin/sh shell
        will be used to interpreted the given script.
    @result The new shell script build phase.
*/
- (PBXObject) createShellScriptBuildPhase:(NSString*)shellScript;	//	PBXShellScriptBuildPhase

// Build phases
// 	PBXHeadersBuildPhase, PBXResourcesBuildPhase, PBXSourcesBuildPhase, 
//	PBXFrameworksBuildPhase (et al)

// functions for adding stuff


// add files to the current target
/*!
    @method addHeaderFile:
    @abstract Adds a file to the headers build phase.
    @param fileRef The file to add. This should be a C/C++/ObjC header file.
    @discussion The file is added to the current target's headers build phase.
        Use this option if you want to compile/index a header file. Future versions
        will allow you to set the public/private attribute.
*/
- (void) addHeaderFile:(PBXObject)fileRef;


/*!
    @method addSourceFile:
    @abstract Adds a file to the sources build phase.
    @param fileRef The file to add. This should be a C/C++/ObjC source file.
    @discussion The file is added to the current target's sources build phase. Files
        added to this phase will be handled by the GNU C/C++/ObjC compiler.
*/
- (void) addSourceFile:(PBXObject)fileRef;


/*!
    @method addResourceFile:
    @abstract Add a file to the resources build phase.
    @param fileRef The file to add. This should be a compiled .rsrc or uncompiled .r/.R file.
        It could also be a nib file, image file, or anything you want put in Product/Contents/Resources/
        
    @discussion The file is added to the current target's resources build phase. Resource files added to
        this phase will be handled by Rez, the resource compiler.
*/
- (void) addResourceFile:(PBXObject)fileRef;


/*!
    @method addFrameworkFile:
    @abstract Adds a file to the frameworks and libraries build phase.
    @param fileRef The framework to add.
    @discussion The file is added to the current target's frameworks and libraries build phase.
        Files added to this build phase are handled by the GNU linker, ld.
*/
- (void) addFrameworkFile:(PBXObject)fileRef;

/*!
    @method addDependentTarget:
    @abstract Adds a dependent target to the current target.
    @param targetRef The dependent target.
    @discussion All the dependent targets of a given target must be compiled before
        the target can be compiled. This allows projects with multiple targets to
        generate files that are used by other targets in the same project.
*/
- (void) addDependentTarget:(PBXObject)targetRef;

/*!
    @method addShellScriptBuildPhase:
    @abstract Adds the given build phase object to the current target.
    @param shellScriptBuildPhase The shell script build phase object.
    @discussion The shell script build phase is appended to the existing
        list of build phases.
*/
- (void) addShellScriptBuildPhase:(PBXObject)shellScriptBuildPhase;

/*!
    @method getProductRef:
    @abstract Gets the product reference of the specified target.
    @param targetRef The target ref to get the product reference of. Pass
        nil to use the current target.
    @discussion
        The product reference is the file reference that points to the target's
        output file. For an application target, this is a file reference for
        a .app bundle. For a framework target, this a file reference for a .framework.
        
        One use of this is to add a library or framework target's product to the
        frameworks and libraries build phase of another target.
    @result A file reference that points to the given target's product (output file).
*/
- (PBXObject) getProductRef:(PBXObject)targetRef;

#pragma mark Build Settings

/*!
    @method getBuildSetting:
    @abstract Gets the value of a build setting.
    @param name The name of the build setting.
    @discussion These are build build settings in the "expert" panel of Project Builder.
    @result The build setting string for the given name, or nil if not found.
*/
- (NSString*) getBuildSetting:(NSString*)name;


/*
    @method setBuildSetting:toValue:
    @abstract Sets the value of a build setting.
    @param name The name of the build setting.
    @param value The new value of the build setting.
    @discussion If a previous value exists it is overwritten.
*/
- (void) setBuildSetting:(NSString*)name toValue:(NSString*)value;


/*!
    @method appendToBuildSetting:value:
    @abstract Appends the given string to an existing build setting.
    @param name The name of the build setting.
    @param value The value to append to the build setting.
    @discussion The build setting is appended, leaving a space
        between it and the previous build setting. If there is no
        previous setting, the build setting is simply added.
*/
- (void) appendToBuildSetting:(NSString*)name value:(NSString*)appendValue;

/*!
    @method getHeaderSearchPaths:
    @abstract Get the HEADER_SEARCH_PATHS build setting.
    @result The HEADER_SEARCH_PATHS build setting.
*/
- (NSString*) getHeaderSearchPaths;


/*!
    @method setHeaderSearchPaths:
    @abstract Set the HEADER_SEARCH_PATHS build setting.
    @param paths The new paths.
*/
- (void) setHeaderSearchPaths:(NSString*)paths;


/*!
    @method addHeaderSearchPath:
    @abstract Add a value to the HEADER_SEARCH_PATHS build setting.
    @param path The value to add.
*/
- (void) addHeaderSearchPath:(NSString*)path;


/*!
    @method getLibrarySearchPaths:
    @abstract Get the LIBRARY_SEARCH_PATHS build setting.
    @result The LIBRARY_SEARCH_PATHS build setting.
*/
- (NSString*) getLibrarySearchPaths;


/*!
    @method setLibrarySearchPaths:
    @abstract Set the LIBRARY_SEARCH_PATHS build setting.
    @param paths The new paths.
*/
- (void) setLibrarySearchPaths:(NSString*)paths;


/*!
    @method addLibrarySearchPath:
    @abstract Add a value to the LIBRARY_SEARCH_PATHS build setting.
    @param path The value to add.
*/
- (void) addLibrarySearchPath:(NSString*)path;


/*!
    @method getFrameworkSearchPaths:
    @abstract Get the FRAMEWORK_SEARCH_PATHS build setting.
    @result The FRAMEWORK_SEARCH_PATHS build setting.
*/
- (NSString*) getFrameworkSearchPaths;


/*!
    @method setFrameworkSearchPaths:
    @abstract Set the FRAMEWORK_SEARCH_PATHS build setting.
    @param paths The new paths.
*/
- (void) setFrameworkSearchPaths:(NSString*)paths;


/*!
    @method addFrameworkSearchPath:
    @abstract Add a value to the FRAMEWORK_SEARCH_PATHS build setting.
    @param path The value to add.
*/
- (void) addFrameworkSearchPath:(NSString*)path;

// cflags editing
//- (NSString*) getOptimizationFlags;
//- (void) setOptimizationFlags:(NSString*)flags;
//- (void) addOptimizationFlag:(NSString*)flag;
//- (void) setEnableDebuggingSymbols:(BOOL)enable; // YES == on, NO == off, use this instead of "-g"
//- (void) getEnableDebuggingSymbols;

/*!
    @method getOtherCFlags:
    @abstract Get the OTHER_CFLAGS build setting.
    @result The OTHER_CFLAGS build setting.
*/
- (NSString*) getOtherCFlags;


/*!
    @method setOtherCFlags:
    @abstract Set the OTHER_CFLAGS build setting.
    @param paths The new paths.
*/
- (void) setOtherCFlags:(NSString*)otherCFlags;


/*!
    @method addOtherCFlag:
    @abstract Add a value to the OTHER_CFLAGS build setting.
    @param path The value to add.
*/
- (void) addOtherCFlag:(NSString*)otherCFlag;


/*!
    @method getOtherLDFlags:
    @abstract Get the OTHER_LDFLAGS build setting.
    @result The OTHER_LDFLAGS build setting.
*/
- (NSString*) getOtherLDFlags;


/*!
    @method setOtherLDFlags:
    @abstract Add a value to the OTHER_LDFLAGS build setting.
    @param path The value to add.
*/
- (void) setOtherLDFlags:(NSString*)otherLDFlags;


/*!
    @method addOtherLDFlag:
    @abstract Add a value to the OTHER_LDFLAGS build setting.
    @param path The value to add.
*/
- (void) addOtherLDFlag:(NSString*)otherLDFlag;

#pragma mark Build Styles
- (NSArray*) getBuildStyles;
- (PBXObject) getBuildStyleWithName:(NSString*)name;
- (NSString*) getBuildStyleValue:(PBXObject)buildStyle withName:(NSString*)name;
- (void) setBuildStyleValue:(PBXObject)buildStyle withName:(NSString*)name toValue:(NSString*)value;
- (BOOL) getBuildStyleValueAppends:(PBXObject)buildStyle withName:(NSString*)name;
- (void) setBuildStyleValueAppends:(PBXObject)buildStyle withName:(NSString*)name toValue:(BOOL)value;
@end

//
// EOF
//