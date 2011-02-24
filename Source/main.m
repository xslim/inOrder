//
//  main.m
//  pbxproj-recode
//
//  Created by Taras Kalapun on 15.12.10.
//  Copyright 2010 Ciklum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Parser.h"

int main (int argc, const char * argv[]) {

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    
    // insert code here…
    
    for (int i=0; i<argc; i++) {
        NSString *argString = [NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
        NSLog(@"incoming parameter: %d, %@", i, argString);
        
    }
    
    
    if (argc < 2) {
        NSLog(@"Please provide valid pbproj file");
        return 0;
    }
    
    NSString *dataFile = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
    
    Parser *p = [[Parser alloc] init];

    [p parseFile:dataFile];
    [p populateFilesAndGroups];
    
    [p printPaths];
	NSLog(@"result %@", p.files);
    
    [p release];
    
    [pool drain];
    return 0;
}
