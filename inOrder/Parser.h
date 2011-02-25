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
    NSDictionary *originalDict;
    NSMutableArray *files;
    NSMutableArray *groups;
	NSString *masterKey;
	NSMutableString *currentGroupKey;
	NSMutableArray *resultArray;
	NSMutableString *groupPath;
	int depthOfPath;
	NSMutableArray *pathArray;
}

@property (retain) NSDictionary *originalDict;
@property (retain) NSMutableArray *files;
@property (retain) NSMutableArray *groups;
@property (retain) NSString *masterKey;
@property (retain) NSMutableString *currentGroupKey;
@property (retain) NSMutableArray *resultArray;
@property (retain) NSMutableString *groupPath;
@property (retain) NSMutableArray *pathArray;

- (void)openFile:(NSString *)fileName;
- (BOOL)saveFileTo:(NSString *)path;
//- (NSString *)archiveFile;
- (void)populateFilesAndGroups;
- (void)printPaths;

@end
