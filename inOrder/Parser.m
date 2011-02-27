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
        self.pathArray = [NSMutableArray array];
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

- (void)populateFilesAndGroups {
    
    NSString *rootObject = [self.originalDict objectForKey:@"rootObject"];
    self.masterKey = [[[self.originalDict objectForKey:@"objects"] objectForKey:rootObject] objectForKey:@"mainGroup"];
    
    NSLog(@"rootObject: %@, mainGroup: %@", rootObject, self.masterKey);
    
    return;
    
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

- (void)pathForKey:(NSString *)key realPath:(NSString *)realPath virtualPath:(NSString *)virtualPath
{
    
    static NSString *kIsa = @"isa";
    static NSString *kFileType = @"PBXFileReference";
	static NSString *kGroupType = @"PBXGroup";

    
    // Create realPath & virtualPath strings
    if (!realPath) realPath = @"";
    if (!virtualPath) virtualPath = @"";
 
    //NSLog(@"starting pathForKey:%@ realPath:%@ virtualPath:%@", key, realPath, virtualPath);
    
    // Get data
    NSDictionary *data = [[self.originalDict objectForKey:@"objects"] objectForKey:key];
    
    // Move only dirs in our project
    NSString *source = [data objectForKey:@"sourceTree"];
    if (!([source isEqualToString:@"SOURCE_ROOT"] ||
          [source isEqualToString:@"<group>"])) {
        //NSLog(@"Bad group: %@", data);
        return;
    }
    
    // Get name & path
    NSString *name = [data objectForKey:kPBName];
    NSString *path = [data objectForKey:kPBPath];
    
    // if name is same as path, xcode ignores it
    
    //if (!path) path = @"<no-path>";
    //if (!name) name = @"<no-name>";
    //if (!path) path = name;
    
    if ([source isEqualToString:@"SOURCE_ROOT"]) {
        realPath = (path) ? path : @"no path?";
        if (name) virtualPath = [virtualPath stringByAppendingPathComponent:name];
    } else if ([source isEqualToString:@"<group>"]) {
        realPath = (path) ? [realPath stringByAppendingPathComponent:path] : [realPath stringByAppendingPathComponent:name];
        
        //realPath = (name) ? [path stringByAppendingString:name] : path;
        
        virtualPath = (name) ? [virtualPath stringByAppendingPathComponent:name] : [virtualPath stringByAppendingPathComponent:path];
    }
    
    // Check if data is group / file
    NSString *isaType = [data objectForKey:kIsa];
    
    // if file
    if ([isaType isEqualToString:kFileType]) {
        
        // use realPath & virtualPath
        // Add it to array
        // finish
        
        if (!path) path = @"";
        if (!name) name = @"";
        
        NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                           key, @"key",
                           virtualPath, @"virtualPath",
                           realPath, @"realPath",
                           name, @"name",
                           path, @"path",
                           source, @"source",
                           nil];
        [self.pathArray addObject:d];
    
    // if group
    } else if ([isaType isEqualToString:kGroupType]) {
    
        // Append group name to realPath & virtualPath
    
        // foreach children
        // Going deeper!
        // pathForKey:childrenKey realPath:&realPath virtualPath:&virtualPath
        
        //virtualPath = [NSString stringWithFormat:@"%@[%@-%@]", virtualPath, source, path];
        
        realPath = (name) ? [path stringByAppendingString:name] : path;
        
        for (NSString *cKey in [data objectForKey:kPBChildren]) {
            [self pathForKey:cKey realPath:realPath virtualPath:virtualPath];
        }
    }
    
}

- (void)constructPaths
{
    
    [self pathForKey:self.masterKey realPath:nil virtualPath:nil];
    NSLog(@"paths: %@", self.pathArray);
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