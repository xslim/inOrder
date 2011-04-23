//
//  Parser.m
//  pbxproj-recode
//
//  Created by Taras Kalapun on 15.12.10.
//  Copyright 2010 Ciklum. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <CoreFoundation/CFDictionary.h>
#import "Parser.h"


@interface Parser ()

- (BOOL)isChildInGroupArray:(NSString *)childKey;
- (int)getFileIndexInArray:(NSString *)fileKey;
- (NSString *)getFileDirectory:(NSString *)fileKey;
- (void)createNecessaryDirsAndCopyFiles:(NSString *)filePath;

@end


@implementation Parser

@synthesize originalDict, files, groups, masterKey, currentGroupKey, resultArray, groupPath, pathArray, changedGroups, projectFilePath;
@synthesize objectBuffer;

static NSString *kPBKey = @"key";
static NSString *kPBName = @"name";
static NSString *kPBPath = @"path";
static NSString *kPBChildren = @"children";
static NSString *kPBSourceTree = @"sourceTree";

- (id)init {
	self = [super init];

	if (self) {
		self.files = [NSMutableArray array];
		self.groups = [NSMutableArray array];
        self.pathArray = [NSMutableArray array];
        
        self.objectBuffer = [NSMutableArray array];
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
    self.projectFilePath = nil;

    self.objectBuffer = nil;
    
	[super dealloc];
}

- (void)organizePaths:(NSString *)filePath
{    
    
    //NSString *filePath = [filePath stringByDeletingLastPathComponent];
    
    self.projectFilePath = filePath;
    
    [self openFile:[filePath stringByAppendingPathComponent:@"project.pbxproj"]];
    
    [self findMasterKey];
    
    [self constructPaths];
    
    NSLog(@"objectBuffer: %@", self.objectBuffer);
    
    //[self printPaths];
    
    //[self createNecessaryDirsAndCopyFiles:filePath];
    
}

- (void)openFile:(NSString *)fileName
{
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

    NSMutableDictionary *mutableCopy = (NSMutableDictionary *)CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)d, kCFPropertyListMutableContainers);
    
	self.originalDict = mutableCopy;

    [mutableCopy release];
    
	//NSLog(@"parsed file:\n%@", d);
}

- (void)findMasterKey
{
    NSString *rootObject = [self.originalDict objectForKey:@"rootObject"];
    self.masterKey = [[[self.originalDict objectForKey:@"objects"] objectForKey:rootObject] objectForKey:@"mainGroup"];
    
    NSLog(@"rootObject: %@, mainGroup: %@", rootObject, self.masterKey);
}

- (void)populateFilesAndGroups
{
    
    
    
    /*
    
	static NSString *kFileType = @"PBXFileReference";
	static NSString *kGroupType = @"PBXGroup";
	static NSString *kConfigurationListType = @"PBXProject";
    static NSString *kIsa = @"isa";
    
    
	NSDictionary *objects = [self.originalDict objectForKey:@"objects"];
    
    [objects enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {
        
        //NSLog(@"sourceTree: %@", [obj objectForKey:@"sourceTree"]);
        //SDKROOT, SOURCE_ROOT, BUILT_PRODUCTS_DIR, <group>, (null), 
        
        NSString *isaType = [obj objectForKey:kIsa];
        
        if ([isaType isEqualToString:kFileType]) {
			NSDictionary *d = [self fileDictFromDict:obj key:key];
			if (d) [self.files addObject:d];
		} else if ([isaType isEqualToString:kGroupType]) {
			NSDictionary *d = [self groupDictFromDict:obj key:key];
			if (d) [self.groups addObject:d];
		} else if ([isaType isEqualToString:kConfigurationListType]) {
            
            if (self.masterKey) {
                NSLog(@"Error! MasterKey already set to: %@, found new: %@", self.masterKey, [obj objectForKey:@"mainGroup"]);
            }
            
			self.masterKey = [obj objectForKey:@"mainGroup"];
		}
    }];
    
    
	//NSLog(@"files: %@", self.files);
	//NSLog(@"groups: %@", self.groups);
     
     */
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
    
    // Move only files in our project
    NSString *source = [dict objectForKey:@"sourceTree"];
    if (!([source isEqualToString:@"SOURCE_ROOT"] ||
        [source isEqualToString:@"<group>"])) {
        NSLog(@"Bad file: %@", dict);
        return nil;
    }
    
    NSString *name = [dict objectForKey:kPBName];
    NSString *path = [dict objectForKey:kPBPath];
    
    if (!name && !path) {
        NSLog(@"Bad %@ file: %@", key, dict); return nil;
    }
    
    if (!name) name = path;
    if (!path) path = name;
    
    /*
    if ([name rangeOfString:@"framework"].location != NSNotFound) {
        NSLog(@"Found framework: %@", dict);
    }
    */
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            key, kPBKey,
            name, kPBName,
            path, kPBPath,
            nil];
}

- (NSDictionary *)groupDictFromDict:(NSDictionary *)dict key:(NSString *)key
{
    
    // Move only dirs in our project
    NSString *source = [dict objectForKey:@"sourceTree"];
    if (!([source isEqualToString:@"SOURCE_ROOT"] ||
          [source isEqualToString:@"<group>"])) {
        NSLog(@"Bad group: %@", dict);
        
        // TODO: clean file array to remove files without group
        
        return nil;
    }
    
    NSString *name = [dict objectForKey:kPBName];
    NSString *path = [dict objectForKey:kPBPath];
    
    //if (name || path) {
    
    if (!name && !path) {
        NSLog(@"Found root group %@ : %@", key, dict);
        name = @""; // not to insert nil
    }
    
    if (!name) name = path;
    if (!path) path = name;
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            key, kPBKey,
            name, kPBName,
            path, kPBPath,
            [dict objectForKey:kPBChildren], kPBChildren,
            nil];
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


- (NSDictionary *)dataForKey:(NSString *)key {
    return [self.originalDict objectForKey:key];
}

- (NSString *)pathForFile:(NSString *)path group:(NSString *)group
{
    return [group stringByAppendingPathComponent:path];
}

- (void)addObjectsToBuffer:(NSArray *)items
{
    NSArray *keyObjects = [items copy];
    
    for (NSString *item in keyObjects) {
        if (![self.objectBuffer containsObject:item]) {
            [self.objectBuffer addObject:item];
        }
    }
    
    [keyObjects release];
}

- (void)pathForKey:(NSString *)key realPath:(NSString *)realPath virtualPath:(NSString *)virtualPath
rootObjects:(NSMutableArray *)rootObjects
{
    
    BOOL firstPass = (!realPath && !virtualPath) ? YES : NO;
    
    static NSString *kIsa = @"isa";
    static NSString *kFileType = @"PBXFileReference";
	static NSString *kGroupType = @"PBXGroup";
    static NSString *kSourceTreeTypeRoot = @"SOURCE_ROOT";
    static NSString *kSourceTreeTypeGroup = @"<group>";

    
    // Create realPath & virtualPath strings
    if (!realPath) realPath = @"";
    if (!virtualPath) virtualPath = @"";
    
    if (!rootObjects) rootObjects = [NSMutableArray array];
    
    // Get data
    NSDictionary *data = [[self.originalDict objectForKey:@"objects"] objectForKey:key];
    
    // Move only dirs in our project
    NSString *source = [data objectForKey:@"sourceTree"];
  
    /*
    if (!([source isEqualToString:kSourceTreeTypeRoot] ||
          [source isEqualToString:kSourceTreeTypeGroup])) {
        //NSLog(@"Bad group: %@", data);
        return;
    }
    */
    
    // Get name & path
    NSString *name = [data objectForKey:kPBName];
    NSString *path = [data objectForKey:kPBPath];
    
    // if name is same as path, xcode ignores it
    
    
    // step up if path=.., clean paths
    NSArray *tmpSplit = [path componentsSeparatedByString:@"../"];
    if ([tmpSplit count] > 1) {
        realPath = [realPath stringByDeletingLastPathComponent];
        path = [path stringByReplacingOccurrencesOfString:@"../" withString:@""];
        //NSLog(@"realPath: %@, data: %@", realPath, data);
    }
    
    //if (!path) path = @"<no-path>";
    //if (!name) name = @"<no-name>";
    //if (!path) path = name;
    
    if ([source isEqualToString:kSourceTreeTypeRoot]) {
        // ignore previous path
        realPath = (path) ? path : @"=== no path ??? ===";
        if (name) {
            virtualPath = [virtualPath stringByAppendingPathComponent:name];
        }
    } else if ([source isEqualToString:kSourceTreeTypeGroup]) {
        //realPath = (path) ? [realPath stringByAppendingPathComponent:path] : [realPath stringByAppendingPathComponent:name];
        
        //realPath = (name) ? [path stringByAppendingString:name] : path;
        
        if (name) {
            virtualPath = [virtualPath stringByAppendingPathComponent:name];
        } else {
            virtualPath = [virtualPath stringByAppendingPathComponent:path];
        }
    } else {
        // We don't parse SDKROOT, BUILT_PRODUCTS_DIR & other source types
        
        [rootObjects removeAllObjects];
        
        return;
    }
    
    // Check if data is group / file
    NSString *isaType = [data objectForKey:kIsa];
    
    // if file
    if ([isaType isEqualToString:kFileType]) {
        
        // use realPath & virtualPath
        // Add it to array
        // finish
        
        if (![source isEqualToString:kSourceTreeTypeRoot]) {
         
            realPath = (path) ? [realPath stringByAppendingPathComponent:path] : [realPath stringByAppendingPathComponent:name];
        }
        
        if ([realPath isEqualToString:virtualPath]) {
            [rootObjects removeAllObjects];
            return;
        }
        
        NSLog(@"%@ -> %@", virtualPath, realPath);
        
        NSLog(@"root objects: %@", rootObjects);
        
        [self addObjectsToBuffer:rootObjects];
        [rootObjects removeAllObjects];
        
        /*
        NSMutableArray *pathsArray = (NSMutableArray *)[path componentsSeparatedByString:@"/"];
        if ([pathsArray count] > 1) {
            
            NSFileManager *fm = [NSFileManager defaultManager];
            if ([fm fileExistsAtPath:[self.projectFilePath stringByAppendingPathComponent:path]]) {
                realPath = path;
            } else { 
                
                //NSMutableArray *copyOfPathsArray = [[NSMutableArray alloc] initWithArray:pathsArray];
                NSMutableArray *realPathArray = (NSMutableArray *)[realPath componentsSeparatedByString:@"/"];
                                
                for (int i = 0; i < [pathsArray count]; i++) {
                    NSString *finalPath = @"";
                    
                    [realPathArray removeLastObject];
                    [pathsArray removeObjectAtIndex:0];
                    
                    for (NSString *realPathStr in realPathArray) {
                        finalPath = [finalPath stringByAppendingPathComponent:realPathStr];
                    }
                    
                    for (NSString *pathStr in pathsArray) {
                        finalPath = [finalPath stringByAppendingPathComponent:pathStr];
                    }
                    
                    if ([fm fileExistsAtPath:[self.projectFilePath stringByAppendingPathComponent:finalPath]]) {
                        realPath = finalPath;
                        break;
                    }             
                }
//                if ([fm fileExistsAtPath:[self.projectFilePath stringByAppendingPathComponent:realPath]]) {
//                    NSLog(@"real path is correct");
//                } else {
//                    
//                    //NSMutableArray *realPathArray = (NSMutableArray *)[realPath componentsSeparatedByString:@"/"];
//                    for (int i = 0; i < [pathsArray count]; i++) {
//                        
//                    }
//                }
            }
         
         
            
        } else {
            
            if (path) {
                realPath = [realPath stringByAppendingPathComponent:path];
            } else {
                realPath = [realPath stringByAppendingPathComponent:name];
            }
            
            NSLog(@"real path %@", realPath);
        }
         
         */
                
//    } else {        
//        realPath = (path) ? [realPath stringByAppendingPathComponent:path] : [realPath stringByAppendingPathComponent:name];        
//    }

    /*    
        //NSLog(@"real path1 %@", realPath);
        if (!path) path = @"";
        if (!name) name = @"";
        
    
    
        if ([virtualPath isEqualToString:realPath]) return;
        
        NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                           //key, @"key",
                           virtualPath, @"virtPath",
                           realPath, @"realPath",
                           name, @"name",
                           path, @"path",
                           //source, @"source",
                           nil];
        [self.pathArray addObject:d];
        
        
        NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] initWithDictionary:data];
        //        
        //NSLog(@"data %@", data);
        //        
        if ([data objectForKey:kPBName]) {
            NSLog(@"virtPath %@", virtualPath);
            [tmpDict setObject:virtualPath forKey:kPBPath];
            [tmpDict setObject:@"SOURCE_ROOT" forKey:kPBSourceTree];
        } else {
            [tmpDict setObject:@"" forKey:kPBPath];
        }
        
        NSMutableDictionary *tmpOriginalDict = [[NSMutableDictionary alloc] initWithDictionary:self.originalDict];
        [tmpOriginalDict setObject:tmpDict forKey:key];
        
        self.originalDict = tmpOriginalDict;
        
        //NSDictionary *data = [[self.originalDict objectForKey:@"objects"] objectForKey:key];

        //[data objectForKey:kPBName];
        //NSString *path = [data objectForKey:kPBPath];
        
        */
    
    // if group
    } else if ([isaType isEqualToString:kGroupType]) {
    
        // Append group name to realPath & virtualPath
    
        // foreach children
        // Going deeper!
        // pathForKey:childrenKey realPath:&realPath virtualPath:&virtualPath
        
        //virtualPath = [NSString stringWithFormat:@"%@[%@-%@]", virtualPath, name, path];
        
        //if (!realPath) realPath = @"";
        //if (!virtualPath) virtualPath = @"";
        
        //if (!path) NSLog(@"no path in group: %@", data);
        
        //realPath = (name) ? [path stringByAppendingString:name] : path;
        if (path) realPath = [realPath stringByAppendingPathComponent:path];
        
        if (firstPass) {
            realPath = @"";
            virtualPath = @"";
        }
        
        [rootObjects addObject:key];
        
        for (NSString *cKey in [data objectForKey:kPBChildren]) {
            [self pathForKey:cKey realPath:realPath virtualPath:virtualPath rootObjects:rootObjects];
        }
    }    
}

- (void)constructPaths
{
    
    [self pathForKey:self.masterKey realPath:nil virtualPath:nil rootObjects:nil];
    //NSLog(@"paths: %@", self.pathArray);    
}

- (BOOL)isComponent:(NSString *)component existsInPath:(NSString *)path
{
    BOOL isComponentExists = NO;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    NSArray *array = [fm contentsOfDirectoryAtPath:path error:&error];
    
    for (NSString *comp in array)
    {
        if ([comp isEqualToString:component])
        {
            isComponentExists = YES;
        }
    }    
    
    return isComponentExists;
}



- (void)createNecessaryDirsAndCopyFiles:(NSString *)projectFilePath_ {
    
    
    NSString *filePath = [projectFilePath_ stringByDeletingLastPathComponent];
    
    //self.projectFilePath = filePath;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSDictionary *dict in self.pathArray)
    {
        //NSString *fileName = [[dict objectForKey:@"virtPath"] lastPathComponent];
        NSString *realPath = [dict objectForKey:@"realPath"];//[self makeRealPath:[dict objectForKey:@"realPath"] basePath:filePath];
        
        NSString *virtualPath = [[dict objectForKey:@"virtPath"] stringByDeletingLastPathComponent];
        NSArray *pathComponents = [virtualPath componentsSeparatedByString:@"/"];
        
        NSError *error = nil;
        NSString *pathToCreate = filePath;
        for (NSString *component in pathComponents)
        {
            pathToCreate = [pathToCreate stringByAppendingPathComponent: component];
        }
        
        if ([fm createDirectoryAtPath:pathToCreate withIntermediateDirectories:YES attributes:nil error:&error])
        {
            //NSLog(@"copied path %@",pathToCreate);
            NSError *error = nil;
            NSString *pathToMove = [filePath stringByAppendingPathComponent:realPath];
            if (![fm fileExistsAtPath:[filePath stringByAppendingPathComponent:[dict objectForKey:@"virtPath"]]]) {            
                [fm moveItemAtPath:pathToMove toPath:[filePath stringByAppendingPathComponent:[dict objectForKey:@"virtPath"]] error:&error];
            }
            
            if (error) {
                //NSLog(@"error while copying files %@", [error localizedDescription]);
            }            
        }
        else
        {
            NSLog(@"error %@", [error localizedDescription]);
        }    
        
        //NSString *path = [filePath stringByAppendingPathComponent:@"project.pbxproj"];
        
        [self saveFileTo:[projectFilePath_ stringByAppendingPathComponent:@"project.pbxproj"]];
    }

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
    //NSLog(@"path array %@", self.pathArray);
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