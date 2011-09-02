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
//- (void)createNecessaryDirsAndCopyFiles:(NSString *)filePath;

@end


@implementation Parser

@synthesize originalDict, files, groups, masterKey, currentGroupKey, resultArray, groupPath, pathArray, changedGroups, projectFilePath, projectPath;
@synthesize objectBuffer, simulate;

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
    self.projectPath = nil;

    self.objectBuffer = nil;
    
	[super dealloc];
}

- (void)organizePaths:(NSString *)filePath
{    
    
    self.projectPath = [filePath stringByDeletingLastPathComponent];
    
    self.projectFilePath = [filePath stringByAppendingPathComponent:@"project.pbxproj"];
    
    [self openFile:self.projectFilePath];
    
    [self findMasterKey];
    
    [self constructPaths];
    
    //NSLog(@"objectBuffer: %@", self.objectBuffer);
    
    [self fixObjects];
    
    /*for (NSString *key in self.objectBuffer) {
        NSDictionary *data = [[self.originalDict objectForKey:@"objects"] objectForKey:key];
        NSLog(@"data: %@", data);
    }*/
    
    //[self printPaths];
    
    //[self createNecessaryDirsAndCopyFiles:filePath];
    
    [self saveFileTo:self.projectFilePath];
    
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
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isSaved = NO;
    
    if (self.simulate) {
        isSaved = YES;
    } else {
        NSError *error = nil;
        if ([fm fileExistsAtPath:path]) {
            [fm removeItemAtPath:path error:&error];
            if (error) NSLog(@"Error: %@", [error localizedDescription]);
        }
        
        isSaved = [self.originalDict writeToFile:path atomically:YES];
    }
    
    
    
    NSLog(@"Saving project: %@, saved: %d", path, isSaved);
    
    return isSaved;
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
    static NSString *kGroupVariantType = @"PBXVariantGroup";
    static NSString *kSourceTreeTypeRoot = @"SOURCE_ROOT";
    static NSString *kSourceTreeTypeGroup = @"<group>";

    
    // Create realPath & virtualPath strings
    if (!realPath) realPath = @"";
    if (!virtualPath) virtualPath = @"";
    
    if (!rootObjects) {
        rootObjects = [NSMutableArray array];
    } else {
        rootObjects = [[rootObjects mutableCopy] autorelease];
    }
    
    // Get data
    NSDictionary *data = [[self.originalDict objectForKey:@"objects"] objectForKey:key];
    
    // Move only dirs in our project
    NSString *source = [data objectForKey:@"sourceTree"];
  
    
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
        if (!name) name = path;
        if (name) {
            virtualPath = [virtualPath stringByAppendingPathComponent:name];
        }
    } else if ([source isEqualToString:kSourceTreeTypeGroup]) {
        
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
    
    if (name && [name rangeOfString:@"xcodeproj"].location != NSNotFound) {
        NSLog(@"xcodeproj name: %@ detected, ignoring!", name);
        return;
    }
    
    if (name && [name rangeOfString:@"Local"].location != NSNotFound) {
        NSLog(@"Local found");
    }
    
    // if file
    if ([isaType isEqualToString:kFileType]) {
        
        
        if (![source isEqualToString:kSourceTreeTypeRoot]) {
         
            realPath = (path) ? [realPath stringByAppendingPathComponent:path] : [realPath stringByAppendingPathComponent:name];
        }
        
        //if (realPath && [realPath rangeOfString:@"plist"].location != NSNotFound) {
        //    NSLog(@"api.plist");
        //}
        
        // if real == virtual, don't proceed
        if ([realPath isEqualToString:virtualPath]) {
            [rootObjects removeAllObjects];
            return;
        }
        
        //NSLog(@"%@ -> %@", virtualPath, realPath);
        
        //NSLog(@"root objects: %@", data, rootObjects);
        
        [self addObjectsToBuffer:rootObjects];
        [rootObjects removeAllObjects];
        
        
        [self moveObject:key fromPath:realPath toPath:virtualPath];
    
    // if group
    } else if ([isaType isEqualToString:kGroupType]) {
    
        // Append group name to realPath
    
        if (path) realPath = [realPath stringByAppendingPathComponent:path];
        
        if (firstPass) {
            realPath = @"";
            virtualPath = @"";
        } else {
            [rootObjects addObject:key];
        }
        
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

- (NSMutableDictionary *)fixPathsInObject:(NSMutableDictionary *)data
{
    
    @synchronized(self) {
        
        static NSString *kIsa = @"isa";
        static NSString *kFileType = @"PBXFileReference";
        static NSString *kGroupType = @"PBXGroup";
        static NSString *kSourceTreeTypeRoot = @"SOURCE_ROOT";
        static NSString *kSourceTreeTypeGroup = @"<group>";
        
        
        // Get name & path
        // if name is same as path, xcode ignores it
        NSString *name = [data objectForKey:kPBName];
        NSString *path = [data objectForKey:kPBPath];
        
        if (name) {
            [data removeObjectForKey:kPBPath];
        } else if (path) {
            name = path;
            [data removeObjectForKey:kPBPath];
        } else {
            NSLog(@"WTF ??");
            return data;
        }
        
        name = [name lastPathComponent];
        
        [data setObject:name forKey:kPBPath];
        
        // Check if data is group / file
        NSString *isaType = [data objectForKey:kIsa];
        if ([isaType isEqualToString:kFileType]) {
            [data setObject:kSourceTreeTypeGroup forKey:@"sourceTree"];
            
            
            
        }
        
    }
    
    return data;
}

- (void)moveObject:(NSString *)objectKey fromPath:(NSString *)fromPath toPath:(NSString *)toPath
{
    NSMutableDictionary *objects = [self.originalDict objectForKey:@"objects"];
    NSMutableDictionary *data = [objects objectForKey:objectKey];
    
    
    data = [self fixPathsInObject:data];
    
    [objects setObject:data forKey:objectKey];
    [self.originalDict setObject:objects forKey:@"objects"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    fromPath = [self.projectPath stringByAppendingPathComponent:fromPath];
    toPath = [self.projectPath stringByAppendingPathComponent:toPath];
    
    NSError *error = nil;

    if (self.simulate) {
        NSLog(@"%@ -> %@", [fromPath stringByReplacingOccurrencesOfString:self.projectPath withString:@""], 
              [toPath stringByReplacingOccurrencesOfString:self.projectPath withString:@""]);
    } else {
        if ([fm createDirectoryAtPath:[toPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error])
        {
            
            if ([fm fileExistsAtPath:fromPath]) {            
                [fm moveItemAtPath:fromPath toPath:toPath error:&error];
                
                NSLog(@"%@ -> %@", fromPath, toPath);
                
                if (error) NSLog(@"error %@", [error localizedDescription]);
            }           
        }
        else
        {
            NSLog(@"error %@", [error localizedDescription]);
        }
    }
    
    
    
    //NSLog(@"New data: %@", data);
}

- (void)fixObjects
{
    
    NSMutableDictionary *objects = [self.originalDict objectForKey:@"objects"];
    
    
    for (NSString *key in self.objectBuffer) {
        NSMutableDictionary *data = [objects objectForKey:key];
        
        data = [self fixPathsInObject:data];
        
        [objects setObject:data forKey:key];
    }
    
    [self.originalDict setObject:objects forKey:@"objects"];
}

@end