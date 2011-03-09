//
//  DataSource.m
//  inOrder
//
//  Created by Taras Kalapun on 27.02.11.
//  Copyright 2011 Ciklum. All rights reserved.
//

#import "DataSource.h"
#import "DataItem.h"

@implementation DataSource


// Data Source methods

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return (item == nil) ? 1 : [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return (item == nil) ? YES : ([item numberOfChildren] != -1);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return (item == nil) ? [DataItem rootItem] : [(DataItem *)item childAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSString *title = (item == nil) ? @"/" : (id)[item relativePath];
    
    BOOL checked = NO;
    BOOL hideCheckbox = [item isFile];
    
    if (hideCheckbox) return title;
    
    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                       title, @"title",
                       [NSNumber numberWithBool:checked], @"state",
                       [NSNumber numberWithBool:hideCheckbox], @"hideCheckbox",
                       nil];
    return d;
}

/*
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if (!item) {

    }
}
*/

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([item isFile]) {
        NSCell *cell = [[NSCell alloc] init];
        [cell setType:NSTextCellType];
        return [cell autorelease];    
    }
    return nil;
}

// Delegate methods

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return NO;
}


@end
