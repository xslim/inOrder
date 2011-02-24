//
//  Parser.h
//  pbxproj-recode
//
//  Created by Taras Kalapun on 15.12.10.
//  Copyright 2010 Ciklum. All rights reserved.
//

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

- (void)parseFile:(NSString *)fileName;
//- (NSString *)archiveFile;
- (void)populateFilesAndGroups;
- (void)printPaths;

@end
