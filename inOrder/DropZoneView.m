//
//  DropZoneView.m
//  inOrder
//
//  Created by Taras Kalapun on 26.02.11.
//  Copyright 2011 Ciklum. All rights reserved.
//

#import "DropZoneView.h"


@implementation DropZoneView


- (id)initWithCoder:(NSCoder *)coder
{
    // Init method called for Interface Builder objects

    self = [super initWithCoder:coder];
    if(self) {
        NSLog(@"initing DropZoneView");
        
        NSArray *dragTypes = [NSArray arrayWithObjects:/*NSCreateFileContentsPboardType(@"xcodeproj"), NSCreateFileContentsPboardType(@"pbxproj"),*/ NSFilenamesPboardType, nil];
        
        [self registerForDraggedTypes:dragTypes];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}



#pragma mark -
#pragma mark Dragging delegates

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSLog(@"performDragOperation sender: %@", sender);
    
    
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        //int numberOfFiles = [files count];
        // Perform operation using the list of files
        
        NSLog(@"performDragOperation files: %@", files);
        
    }
    return YES;
}

//Destination Operations
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    // method called whenever a drag enters our drop zone
    //NSLog(@"draggingEntered: %@", sender);
    
    // Check if the pasteboard contains image data and source/user wants it copied
    /*
     if ( [NSImage canInitWithPasteboard:[sender draggingPasteboard]] &&
     [sender draggingSourceOperationMask] &
     NSDragOperationCopy ) {
     highlight=YES;//highlight our drop zone
     [self setNeedsDisplay: YES];
     return NSDragOperationCopy; //accept data as a copy operation
     }
     */
    
    //NSFilenamesPboardType
    
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        if (sourceDragMask & NSDragOperationLink) {
            return NSDragOperationLink;
        } else if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
    }
    
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    // method called whenever a drag exits our drop zone
    //NSLog(@"draggingExited: %@", sender);
    
    //highlight=NO;//remove highlight of the drop zone
    //[self setNeedsDisplay: YES];
}


@end

