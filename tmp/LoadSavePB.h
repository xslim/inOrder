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
    @header LoadSavePB
*/
#import <Foundation/Foundation.h>

/*!
    @class 		LoadSavePB : NSObject
    @abstract 	Class to load/save the Project Builder Property List-based project format.
    @discussion This class contains functionality for loading project.pbxproj
                files into an NSMutableDictionary. Additionally, it provides
                essential functionality for linking serialized dictionaries
                in the project upon loading, and reserializing the same
                dictionaries prior to saving back to disk. In order to ensure
                that dictionaries added to the project can be reserialized, they
                must be created through the provided interface.
                
                
                The following example adds a new group called "myGroup". Note that the "files"
                array is cleared to avoid creating a cycle in the graph. If your editing creates
                cycles in the graph -flatten will crash due to exhausting available stack space.
                
                <blockquote><pre>
                #import "LoadSavePB.h"
                
                - (void)testLoadSavePB
                {
                    NSString* 				projectFile = &#64;"MyProject.pbproj/project.pbxproj";
                    LoadSavePB* 			loadSave;
                    NSMutableDictionary*	root;
                    NSMutableDictionary*	group;
                    NSMutableArray*			groupFiles;
                    NSMutableDictionary* 	newGroup;
                    NSMutableArray*			newGroupFiles;
                    
                    loadSave = [ [ LoadSave alloc ] initWithFile:projectFile ];
                    [ loadSave link ];
                    root  = [ loadSave getLinkedRootObject ];
                    
                    group = [ root objectForKey:&#64;"mainGroup" ];
                    groupFiles = [ group objectForKey:&#64;"files" ];
                    
                    newGroup  = [ loadSave createObjectWithClassName:&#64;"PBXGroup" ];
                    newGroupFiles = [ newGroup objectForKey:&#64;"files" ];
                    [ newGroupFiles removeAllObjects ];
                    
                    [ newGroup setObject:&#64;"myGroup" forKey:&#64;"name" ];
                    [ groupFiles addObject:newGroup ];
                    
                    [ loadSave flatten ];
                    [ loadSave dumpToFile:projectFile ];
                }
                </pre></blockquote>
                
*/
@interface LoadSavePB : NSObject 
{
    NSMutableDictionary		*plist;           // property list of the .pbxproj file
    
	BOOL                    wasLink;         // tells if link: was already called
											 // so we don't try to link more than once
	
	BOOL                    wasFlatten;      // tells if flatten: was already called
	                                         // so we don't try to flatten more than once
                                             
	// Dictionary of info about classes used for PBX objects, inferred from project file
	//     keyed by the pbxproj object type names
	//     The object descriptions are used to create/modify/destroy
	//     the real entries in the loaded plist
	NSMutableDictionary  	*classDescDict;
        
	// The object root of all linked catalog files and the project file
	NSMutableArray          *objectRoot;
	
	// Stack used to prevent infinite recursion when linking/flattening, for example when linking an
	// object whose children link back to the same object
	NSMutableArray          *linkStack;
}

/*!
    @method 	initWithFile
    @abstract	Initializes an instance of LoadSavePB
    
    @param		path			The slash-delimited path to a project.pbxproj file.
                                This file is typically located in the MyProject.pbproj bundle.
    @result		The initialized object.
    
    @discussion	This method will create an NSMutableDictionary instance for the given file
                on disk. The project will not be linked (see definition of <a href="#link">-link<a>).
*/
- (id) initWithFile:(NSString*)path;


/*!
    @method	link
    @abstract Links serialized dictionaries into the project graph.
    
    @discussion		Project Builder stores projects in a flattened format, with common instances
                    factored out to preserve object relationships in the graph. This factoring
                    is required since CoreFoundation's XML saver creates copies of the same instances. 
                    Without factoring, this copying would destroy object relationships in the graph - 
                    not to mention making the saved files considerably larger. Unfortunately, this factoring
                    can make the project file difficult to manipulate.
                    
                    When saving a project in Project Builder, the factored-out objects in the graph
                    are replaced with a string containing a custom UUID,
                    or Universally Unique IDentifier (note this is not the same format as CFUUID, but a
                    similiar concept). The object that the UUID refers to is placed into a dictionary
                    which is stored at the root of the graph. This procedure recursively traverses the 
                    project graph, replacing found UUID's with objects in the object dictionary.   
                    
                    This procedure ondoes the factoring that Project Builder performs. In the process,
                    it builds definitions of Project Builder objects by inferring each definition from
                    an example instance found in the loaded project. The result is a complete graph
                    of the project, and a means to create new objects without sacrificing the ability
                    to reflatten the graph.
                    
                    The linked graph is placed in the root object, with the key "linkedRootObject".
                    
                    You can dump a linked project to disk using <a href="#dumpToFile">-dumpToFile<a>
                    to see what the linked graph looks like in memory (use Property List Editor to view it). 
                    
                    You can also call NSLog([ loadSave getLinkedGraph ]) to see the complete structure 
                    in the console.
                    
                    You must undo this process with <a href="#flatten">-flatten<a> to create a project file 
                    that Project Builder can parse.
*/
- (void) link;

/*!
    @method 	getLinkedGraph
    @abstract	Gets the linked project graph.
    
    @result		The linked project graph, ready for editing.
    
    @discussion This method gets the linked project graph. 
                If if project is not linked it will be linked first.

                Use this method to get the project graph. You can
                then use Foundation to edit the graph.
*/
- (NSMutableDictionary*) getLinkedGraph;


/*!
    @method 	flatten
    @abstract 	Reverses the linking process and creates a Project Builder-compatible graph.

    @discussion		This method serializes select objects in the 
                    graph based on knowledge gained in the linking process.
                    After flattening, a linked graph should be openable by Project Builder.
    
                    This effectively reverses <a href="#link">-link<a>.
    
                    The object descriptions dictionary is used to figure
                    out what parts of the each object need to be factored out.
                    
                    See <a href="#link">-link<a> for more detail on the linking/flattening process.
*/
- (void) flatten;


/*!
    @method 	dumpToFile
    @abstract	Directly saves the loaded and/or modified NSMutableDictionary to disk.

    @param		path	Slash-delimited path to an output file. Usually you want this to be
                        the project.pbxproj file.
                    
    @discussion	This method dumps the loaded version of the .pbxproj file to disk.
                    
                If the project was linked and not flattened, it will be larger 
                than the original, since there are multiple copies of the same
                object in there.
                
                To get a Project Builder-compatible file, you must call
                <a href="#flatten">-flatten<a> if you ever called <a href="#link">-link<a>, 
                before you dump to a file.
                
                The output file can be examined with Property List Editor.
*/
- (void) dumpToFile:(NSString*)path;


/*!
    @method     createObjectWithClassName
    @abstract	Creates new object instances for adding to the project graph.
    
    @param		className	The name of the Project Builder class.
    @result		An NSMutableDictionary that represents the object's properties.
    
    @discussion Create an object of the given class. An "object" as used in this context
                is actually a description of a real Objective-C object. The object is
                described using key-value coding where keys are object field names and values
                are object field values.
                
                This mechanism ensures that new objects can be serialized when
                the graph is flattened.
                
                The initial field values of the object are taken from an "example" object that is
                discovered during the linking process. Clients are responsible for changing
                objects as they see fit, but should always create them through this interface.
                
                This method will fail if there is no description of the desired class. Descriptions
                are created when calling <a href="#link">-link<a> and
                <a href="#loadCatalogFile">-loadCatalogFile<a>.
*/
- (NSMutableDictionary*) createObjectWithClassName:(NSString*)className;



/*!
    @method			loadCatalogFile
    @abstract		Loads an additional project file to act as a catalog for created objects.
    
    @param			path		The slash-delimited path to a project.pbxproj file.
    @result			An NSMutableDictionary that represents the loaded file, in linked form 
                    (see definition of <a href="#link">-link<a>). This value is provided for 
                    interested parties, and can safely be ignored.
    
    @discussion		Sometimes the original project will not contain instances (hence definitions)
                    of the objects one wishes to create. In this case, one can
                    load any number of additional "catalog" project files that contain
                    those instances, using the object definitions from the catalog file.
                    
                    Object definitions are inferred from example instances found in loaded project files.
                    A new object cannot be created without a definition, since
                    a definition is required to serialize the object.
                    
                    If a catalog file contains a different definition of a previously
                    defined object, the new definition will be ignored.
                    
                    Multiple catalog files can be loaded in sequence - there is no
                    limit (besides available memory) to how many catalogs can be loaded.
                    
                    A catalog file cannot be unloaded - the loading process is irreversible. 
                    The only way out - for example if you wanted to load a different definition 
                    for an object - is to release the LoadSavePB instance and reload everything 
                    with the new file.
					
					In practice, CMEngine uses a catalog file that contains all of the known
					xcode objects, to make the full set of objects available to EditPB class
*/
- (NSMutableDictionary*) loadCatalogFile:(NSString*)path;


/*!
    @method         objectRoot
    @abstract       Returns the "object root" consisting of all linked projects and catalog files
    
    @param
    @result	    Any array containing every linked project
    
    @discussion     With XCode, it became necessary/desireable to clone an object that is present
                    in a catalog file or project without having to refer to just its class name.
                    
                    By obtaining the object root, it is now possible to "seek out" an object using
                    sophisticated criteria, rather than just the limited facility that createObjectWithClassName
                    provides.
                    
                    This is the strategy used to clone different PBXNativeTarget objects for the different
                    native target types (application, static lib, dynamic lib, tool, framework, etc)
*/
- (NSArray*) objectRoot;
@end

//
// EOF
//