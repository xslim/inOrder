//
//  Parser.h
//  pbxproj-recode
//
//  Created by Taras Kalapun on 15.12.10.
//  Copyright 2010 Ciklum. All rights reserved.
//

/*
 
 Console application was like this:
 
 for (int i=0; i<argc; i++) {
 NSString *argString = [NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
 NSLog(@"incoming parameter: %d, %@", i, argString);
 
 }
 
 
 if (argc < 2) {
 NSLog(@"Please provide valid pbproj file");
 return 0;
 }
 
 NSString *dataFile = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
 
 Parser *p = [[Parser alloc] init];
 
 [p parseFile:dataFile];
 [p populateFilesAndGroups];
 
 [p printPaths];
 NSLog(@"result %@", p.files);
 
 [p release];
 
 */

#import <Foundation/Foundation.h>


// plutil -convert xml1 -o - myproj.xcodeproj/project.pbxproj ?

@interface Parser : NSObject {

    NSMutableArray *files;
    NSMutableArray *groups;
	NSString *masterKey;
	NSMutableString *currentGroupKey;
	NSMutableArray *resultArray;
	NSMutableString *groupPath;
	int depthOfPath;
	NSMutableArray *pathArray;
    
    // The object root of all linked catalog files and the project file
	NSMutableArray          *objectRoot;
	
	// Stack used to prevent infinite recursion when linking/flattening, for example when linking an
	// object whose children link back to the same object
	NSMutableArray          *linkStack;
}

@property (retain) NSMutableDictionary *originalDict;
@property (retain) NSMutableArray *files;
@property (retain) NSMutableArray *groups;
@property (retain) NSString *masterKey;
@property (retain) NSMutableString *currentGroupKey;
@property (retain) NSMutableArray *resultArray;
@property (retain) NSMutableString *groupPath;
@property (retain) NSMutableArray *pathArray;
@property (retain) NSString *projectFilePath;
@property (retain) NSString *projectPath;

@property (retain) NSMutableArray *objectBuffer;

@property (retain) NSMutableArray *changedGroups;

@property (assign) BOOL simulate;

- (void)addObjectsToBuffer:(NSArray *)items;
- (void)pathForKey:(NSString *)key realPath:(NSString *)realPath virtualPath:(NSString *)virtualPath
       rootObjects:(NSMutableArray *)rootObjects;

- (void)openFile:(NSString *)fileName;
- (void)organizePaths:(NSString *)filePath;
- (void)findMasterKey;

- (BOOL)saveFileTo:(NSString *)path;
//- (NSString *)archiveFile;
- (void)populateFilesAndGroups;

- (void)constructPaths;

- (void)printFiles;
- (void)printGroups;
- (void)printPaths;

- (void)moveObject:(NSString *)objectKey fromPath:(NSString *)fromPath toPath:(NSString *)toPath;
- (void)fixObjects;

@end
