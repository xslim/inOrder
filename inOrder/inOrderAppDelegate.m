//
//  inOrderAppDelegate.m
//  inOrder
//
//  Created by Taras Kalapun on 24.02.11.
//  Copyright 2011 Ciklum. All rights reserved.
//

#import "inOrderAppDelegate.h"

@implementation inOrderAppDelegate

@synthesize window, dropZone;

- (void)dealloc {
    self.window = nil;
    self.dropZone = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Application delegates

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    

    
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

#pragma mark -
#pragma mark Dragging delegates

// Handle a file dropped on the dock icon
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)path
{
    
    // !! Do something here with the file path !!
    NSLog(@"Dropped file: %@ from %@", path, sender);
    
    
    //NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
	//NSSize newSize = NSMakeSize([image frame].size.width, [image frame].size.height);
	
    
    return YES;
}


@end
