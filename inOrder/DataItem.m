//
//  OutlineDictionary.m
//  inOrder
//
//  Created by Taras Kalapun on 27.02.11.
//  Copyright 2011 Ciklum. All rights reserved.
//

#import "DataItem.h"


@implementation DataItem

static DataItem *rootItem = nil;

#define IsALeafNode ((id)-1)

- (id)initWithPath:(NSString *)path parent:(DataItem *)obj {
    if ((self = [super init])) {
        relativePath = [[path lastPathComponent] copy];
        parent = obj;
    }
    return self;
}

+ (DataItem *)rootItem {
    if (rootItem == nil) rootItem = [[DataItem alloc] initWithPath:@"/" parent:nil];
    return rootItem;       
}

- (void)dealloc {
    if (children != IsALeafNode) [children release];
    [relativePath release];
    [super dealloc];
}

// Creates and returns the array of children
// Loads children incrementally
//
- (NSArray *)children {
    if (children == NULL) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *fullPath = [self fullPath];
        BOOL isDir, valid = [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
        if (valid && isDir) {
            NSArray *array = [fileManager contentsOfDirectoryAtPath:fullPath error:NULL];
            if (!array) {   // This is unexpected
                children = [[NSMutableArray alloc] init];
            } else {
                NSInteger cnt, numChildren = [array count];
                children = [[NSMutableArray alloc] initWithCapacity:numChildren];
                for (cnt = 0; cnt < numChildren; cnt++) {
                    DataItem *item = [[DataItem alloc] initWithPath:[array objectAtIndex:cnt] parent:self];
                    [children addObject:item];
                    [item release];
                }
            }
        } else {
            children = IsALeafNode;
        }
    }
    return children;
}

- (NSString *)relativePath {
    return relativePath;
}

- (NSString *)fullPath {
    return parent ? [[parent fullPath] stringByAppendingPathComponent:relativePath] : relativePath;
}

- (DataItem *)childAtIndex:(NSInteger)n {
    return [[self children] objectAtIndex:n];
}

- (NSInteger)numberOfChildren {
    id tmp = [self children];
    return (tmp == IsALeafNode) ? (-1) : [tmp count];
}

@end
