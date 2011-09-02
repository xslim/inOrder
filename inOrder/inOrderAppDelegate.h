//
//  inOrderAppDelegate.h
//  inOrder
//
//  Created by Taras Kalapun on 24.02.11.
//  Copyright 2011 Ciklum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface inOrderAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
    NSView *mainView;
    NSView *dropZone;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) IBOutlet NSView *mainView;
@property (retain) IBOutlet NSView *dropZone;

- (IBAction)testParser;

@end
