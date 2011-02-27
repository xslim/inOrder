//
//  OutlineDictionary.h
//  inOrder
//
//  Created by Taras Kalapun on 27.02.11.
//  Copyright 2011 Ciklum. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DataItem : NSObject {
    NSString *relativePath;
    DataItem *parent;
    NSMutableArray *children;
}

+ (DataItem *)rootItem;
- (NSInteger)numberOfChildren;			// Returns -1 for leaf nodes
- (DataItem *)childAtIndex:(NSInteger)n;	// Invalid to call on leaf nodes
- (NSString *)fullPath;
- (NSString *)relativePath;

@end
