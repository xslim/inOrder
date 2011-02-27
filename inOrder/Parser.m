//
//  Parser.m
//  pbxproj-recode
//
//  Created by Taras Kalapun on 15.12.10.
//  Copyright 2010 Ciklum. All rights reserved.
//

#import "Parser.h"


@interface Parser ()

- (BOOL)isChildInGroupArray:(NSString *)childKey;
- (int)getFileIndexInArray:(NSString *)fileKey;
-(NSString *)getFileDirectory:(NSString *)fileKey;

@end


@implementation Parser

@synthesize originalDict, files, groups, masterKey, currentGroupKey, resultArray, groupPath, pathArray;

static NSString *kPBKey = @"key";
static NSString *kPBName = @"name";
static NSString *kPBPath = @"path";
static NSString *kPBChildren = @"children";

- (id)init {
	self = [super init];

	if (self) {
		self.files = [NSMutableArray array];
		self.groups = [NSMutableArray array];
	}

	return self;
}

- (void)dealloc {
	self.originalDict = nil;
	self.files = nil;
	self.groups = nil;
	self.masterKey = nil;
	self.currentGroupKey = nil;
	self.resultArray = nil;
	self.groupPath = nil;
	self.pathArray = nil;

	[super dealloc];
}

- (void)openFile:(NSString *)fileName {
	NSData *data = [NSData dataWithContentsOfFile:fileName];

	if (!data) {
		NSLog(@"Data file is empty");
		return;
	}

	NSError *error = nil;
	NSDictionary *d = [NSPropertyListSerialization propertyListWithData:data
	                   options:NSPropertyListOpenStepFormat
	                   format:NULL
	                   error:&error];


	if (error) {
		NSLog(@"Error reading %@ : %@", fileName, error);
		return;
	}

	self.originalDict = d;

	//NSLog(@"parsed file:\n%@", d);
}

- (BOOL)saveFileTo:(NSString *)path
{
    return [self.originalDict writeToFile:path atomically:YES];
}

//- (NSString *)archiveFile {
//
//    //test
//    NSDictionary *newDictionary = self.originalDict;
//
//    NSError *error = nil;
//    NSData *data = [NSPropertyListSerialization dataWithPropertyList:newDictionary
//                                                              format:NSPropertyListOpenStepFormat
//                                                             options:NSPropertyListOpenStepFormat
//                                                               error:&error];
//
//    if (error) {
//        NSLog(@"Error making data %@", error);
//        return nil;
//    }
//
//
//    //NSLog(@"new data: %@", data);
//
//    return nil;
//}

- (NSDictionary *)fileDictFromDict:(NSDictionary *)dict key:(NSString *)key
{
    NSString *name = [dict objectForKey:kPBName];
    NSString *path = [dict objectForKey:kPBPath];
    
    if (!name) name = path;
    
    if ([name rangeOfString:@"framework"].location != NSNotFound) {
        NSLog(@"Found framework: %@", dict);
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            key, kPBKey,
            name, kPBName,
            path, kPBPath,
            nil];
}

- (NSDictionary *)groupDictFromDict:(NSDictionary *)dict key:(NSString *)key
{
    NSString *name = [dict objectForKey:kPBName];
    NSString *path = [dict objectForKey:kPBPath];
    
    //if (name || path) {
    
    if (!name) name = path;
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            key, kPBKey,
            name, kPBName,
            path, kPBPath,
            [dict objectForKey:kPBChildren], kPBChildren,
            nil];
}

- (void)populateFilesAndGroups {
	static NSString *kFileType = @"PBXFileReference";
	static NSString *kGroupType = @"PBXGroup";
	static NSString *kConfigurationListType = @"PBXProject";
    static NSString *kIsa = @"isa";


	NSDictionary *objects = [self.originalDict objectForKey:@"objects"];
    
    [objects enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {

        NSString *isaType = [obj objectForKey:kIsa];
        
        if ([isaType isEqualToString:kFileType]) {
			NSDictionary *d = [self fileDictFromDict:obj key:key];
			[self.files addObject:d];
		} else if ([isaType isEqualToString:kGroupType]) {
			NSDictionary *d = [self groupDictFromDict:obj key:key];
			[self.groups addObject:d];
		} else if ([isaType isEqualToString:kConfigurationListType]) {
            
            if (self.masterKey) {
                NSLog(@"Error! MasterKey already set to: %@, found new: %@", self.masterKey, [obj objectForKey:@"mainGroup"]);
            }
            
			self.masterKey = [obj objectForKey:@"mainGroup"];
		}
    }];


	//NSLog(@"files: %@", self.files);
	//NSLog(@"groups: %@", self.groups);
}

- (void)printFiles {
    NSLog(@"Files: ");
    [self.files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSLog(@"\t%@ %@ -> %@", [obj objectForKey:kPBKey], [obj objectForKey:kPBName], [obj objectForKey:kPBPath]);
    }];
}

- (void)printGroups {
    NSLog(@"Groups: ");
    [self.groups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSLog(@"\t%@ %@ -> %@", [obj objectForKey:kPBKey], [obj objectForKey:kPBName], [obj objectForKey:kPBPath]);
    }];
}

- (void)printPaths {
	//NSLog(@"%@", self.files);
    
	NSString *groupToSearch;
	if (self.currentGroupKey) {
		groupToSearch = self.currentGroupKey;
	} else {
		groupToSearch = self.masterKey;
	}

	for (NSDictionary *group in self.groups) {
		if ([[group objectForKey:@"key"] isEqualToString:groupToSearch]) {
			if (!self.groupPath) {
				self.groupPath = [[NSMutableString alloc] init];
			}

			if ([group objectForKey:@"name"]) {
				if (!self.pathArray) {
					self.pathArray = [[NSMutableArray alloc] init];
				}

				[self.pathArray addObject:[NSString stringWithFormat:@"/%@", [group objectForKey:@"name"]]];
			}

			NSArray *children = [group objectForKey:@"children"];

			for (int i = 0; i < [children count]; i++) {
				BOOL noFilesInDirectory = YES;
				NSString *childrenKey = [children objectAtIndex:i];
				if ([self isChildInGroupArray:childrenKey]) {
					self.currentGroupKey = [NSMutableString stringWithString:childrenKey];
					[self printPaths];
				} else {
					noFilesInDirectory = NO;
					self.currentGroupKey = nil;
					int fileIndex = [self getFileIndexInArray:childrenKey];

					NSMutableDictionary *fileInfoDict = [[NSMutableDictionary alloc] init];
					
					[fileInfoDict setObject:[[self.files objectAtIndex:fileIndex] objectForKey:@"name"] forKey:@"fileName"];

					NSMutableString *resultPathString = [[NSMutableString alloc] init];
					for (NSString *pathName in self.pathArray) {
						[resultPathString appendString:pathName];
					}

					if (self.groupPath) {
						[fileInfoDict setObject:resultPathString forKey:@"fileGroupPath"];
					}
					[resultPathString release];

					[fileInfoDict setObject:childrenKey forKey:@"fileKey"];
					
					NSString *realPath;
					if ([[self getFileDirectory:childrenKey] length] == 0) {
						//NSLog(@"result path string %@", resultPathString);
						realPath = resultPathString;
					}
					else
					{
						//NSLog(@"result file directory %@", [self getFileDirectory:childrenKey]);
						realPath = [self getFileDirectory:childrenKey]; 						
					}
					
					[fileInfoDict setObject:realPath forKey:@"fileRealPath"];

					if (!self.resultArray) {
						self.resultArray = [NSMutableArray array];
					}
					[self.resultArray addObject:fileInfoDict];

					if (i == [children count] - 1) {
						if ([self.pathArray count] > 0) {
							[self.pathArray removeLastObject];
							self.groupPath = nil;
						}
					}
					[fileInfoDict release];
				}

				if (noFilesInDirectory) {
					if (i == [children count] - 1) {
						if ([self.pathArray count] > 0) {
							[self.pathArray removeLastObject];
						}
					}
				}
			}
		}
	}
}

-(NSString *)getFileDirectory:(NSString *)fileKey
{
	NSString *path;
	for(NSDictionary *dict in self.files)
	{
		path = [dict objectForKey:@"path"];
		if ([[dict objectForKey:@"key"] isEqualToString:fileKey]) {
			if (![[dict objectForKey:@"name"] isEqualToString:[dict objectForKey:@"path"]]) {
				//NSLog(@"name is equal to path");				
				return @"";
			}
		}
	}
	return path;
}

- (BOOL)isChildInGroupArray:(NSString *)childKey {
	for (int y = 0; y < [self.groups count]; y++) {
		NSDictionary *group = [self.groups objectAtIndex:y];
		
		if ([[group objectForKey:@"key"] isEqualToString:childKey]) {
			return YES;
		}
	}

	return NO;
}

- (int)getFileIndexInArray:(NSString *)fileKey {
	for (int i = 0; i < [self.files count]; i++) {
		NSDictionary *file = [self.files objectAtIndex:i];
		if ([[file objectForKey:@"key"] isEqualToString:fileKey]) {
			return i;
		}
	}

	return 0;
}

@end