//
//  inOrderAppDelegate.m
//  inOrder
//
//  Created by Taras Kalapun on 24.02.11.
//  Copyright 2011 Ciklum. All rights reserved.
//

#import "inOrderAppDelegate.h"
#import "Parser.h"

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
    [self.window setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"bgPattern.png"]]];
    NSButton *btn = [self.window standardWindowButton:NSWindowZoomButton];
    [btn setHidden:YES];


    [self testParser];
    
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

#pragma mark -
#pragma mark IBActions

- (IBAction)testParser
{
    Parser *p = [[Parser alloc] init];
    
    NSString *dataFile = [[NSBundle bundleForClass:[self class]] pathForResource:@"project" ofType:@"pbxproj"];
    [p openFile:dataFile];
    
    [p populateFilesAndGroups];
    
    [p printFiles];
    [p printGroups];
    
    //[p printPaths];
    //NSLog(@"result %@", p.files);
    
    [p release];
    
}


@end
